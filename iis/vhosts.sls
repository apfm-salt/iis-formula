### Deal with IIS vhosts
{%- set webroot = salt['pillar.get']('iis:webroot', 'c:\inetpub\sites') %}
main_webroot:
  file.directory:
    - name: {{ webroot }}
    - user: Administrator

{%- for vhost, vhost_data in salt['pillar.get']('iis:vhosts', {}).items() %}
{%- set vhost_site = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':site', vhost ) %}
{%- set vhost_apppool = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apppool', vhost_site ) %}
{%- set vhost_webroot = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':webroot', webroot ~ '\\' ~ vhost_apppool ) %}
{%- set vhost_hash = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':hash', '') %}
{%- set vhost_skip_verify = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':skip_verify', True) %}
{%- set vhost_username = vhost_site|lower|replace('.','_')|replace('-','_')|replace('www_','') %}
{%- set vhost_username = vhost_username[:20] %}
{%- if vhost_username[-1] == '_' %}
{%- set vhost_username = vhost_username[:-1] %}
{%- endif %}

# Create user
{{ vhost }}_user:
  user.present:
    - name: {{ vhost_username }}
    {# - password: {{ vhost_data.password }} -#}
    - home: {{ vhost_webroot }}
    - createhome: True
    - win_description: 'Web user for {{ vhost }}'

# Create Webroot (createHome: True doesn't appear to be doing this)
{{ vhost }}_webroot:
  file.directory:
    - name: {{ vhost_webroot }}
    - user: {{ vhost_username }}
    - require:
      - user: {{ vhost }}_user
{%- if 'source' in vhost_data %}
      - archive: {{ vhost }}_archive
{%- endif %}

{%- if 'source' in vhost_data %}
{{ vhost }}_archive:
  archive.extracted:
    - name: {{ vhost_webroot }}
    - source: {{ vhost_data.source }}
    - enforce_toplevel: False
    - skip_verify: {{ vhost_skip_verify }}
{%- if vhost_hash != '' %}
    - hash: {{ vhost_hash }}
{%- endif %}
{%- endif %}

# Create vhost & application pool
{{ vhost }}_website:
  win_iis.deployed:
    - name: {{ vhost_site }}
    - sourcepath: {{ vhost_webroot }}
    - apppool: {{ vhost_apppool }}
    - hostheader: {{ vhost }}
    - ipaddress: "{{ vhost_data.ip if 'ip' in vhost_data else '*' }}"
    - port: {{ vhost_data.port if 'port' in vhost_data else '80' }}
    - require:
      - win_servermanager: IIS_Webserver
      - file: {{ vhost }}_webroot

{%- for alt_name in salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':alt_names', []) %}
{{ alt_name }}_binding:
  win_iis.create_binding:
    - name: {{ alt_name }}
    - site: {{ vhost_site }}
    - hostheader: {{ alt_name }}
    - ipaddress: "{{ vhost_data.ip if 'ip' in vhost_data else '*' }}"
    - port: {{ vhost_data.port if 'port' in vhost_data else '80' }}
    - require:
      - win_servermanager: IIS_Webserver
      - file: {{ vhost }}_webroot
      - win_iis: {{ vhost }}_website
{% endfor %}

{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost_apppool }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ vhost_data.pipelinemode if 'pipelinemode' in vhost_data else 'Integrated' }}
        processModel.maxProcesses: {{ vhost_data.processes if 'processes' in vhost_data else 1 }}
        processModel.userName: {{ vhost_username }}
        {# processModel.password: {{ vhost_data.password }} -#}
        processModel.identityType: SpecificUser
        startMode: {{ vhost_data.startmode if 'startmode' in vhost_data else 'OnDemand' }}
    - require:
      - win_servermanager: IIS_Webserver
      - win_iis: {{ vhost }}_website

{%- for vdir,vdir_data in salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':vdirs', {}).items() %}
{%- set vdir_id = vdir|lower|replace('.','_')|replace('-','_')|replace('/','') %}
{%- set vdir_hash = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':vdirs:' ~ vdir ~ ':hash', '') %}
{%- set vdir_skip_verify = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':vdirs:' ~ vdir ~ ':verify', True) %}
{%- set vdir_site = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':vdirs:' ~ vdir ~ ':site', vhost_site) %}
{%- set vdir_app = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':vdirs:' ~ vdir ~ ':app', vhost_apppool) %}
{{ vhost }}_vdir_{{ vdir_id }}:
  win_iis.create_vdir:
    - name: {{ vdir }}
    - site: {{ vdir_site }}
    - app: {{ vdir_app }}
    - sourcepath: {{ vdir_data.path }}
{%- if 'source' in vdir_data %}
    - require:
      - archive: {{ vhost }}_{{ vdir_id }}_archive
{%- endif %}

{%- if 'source' in vdir_data %}
{{ vhost }}_{{ vdir_id }}_archive:
  archive.extracted:
    - name: {{ vdir_data.path }}
    - source: {{ vdir_data.source }}
    - enforce_toplevel: False
    - skip_verify: {{ vdir_skip_verify }}
{%- if vdir_hash != '' %}
    - hash: {{ vdir_hash }}
{%- endif %}
{%- endif %}
{%- endfor %}

{%- endfor %}
