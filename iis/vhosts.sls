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
{%- set vhost_username = vhost_site|lower|replace('.','_')|replace('-','_')|replace('www_','') %}
{%- set vhost_username = vhost_username[:20] %}
{%- if vhost_username[-1] == '_' %}
{%- set vhost_username = vhost_username[:-1] %}
{%- endif %}

# Create user
{{ vhost }}_user:
  user.present:
    - name: {{ vhost_username }}
    - password: {{ vhost_data.password }}
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
{{ vhost }}_archive:
  archive.extracted:
    - name: "{{ vhost_webroot }}"
    - source: "{{ vhost_data.source }}"
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

{{ vhost }}_site_settings:
  win_iis.container_setting:
    - name: {{ vhost_site }}
    - container: Sites
    - settings:
        applicationDefaults.preloadEnabled: {{ vhost_data.preload if 'preload' in vhost_data else 'False' }}
    - require:
      - win_servermanager: IIS_Webserver
      - chocolatey: dotnetfx
      - win_iis: {{ vhost }}_website

{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost_apppool }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ vhost_data.pipelinemode if 'pipelinemode' in vhost_data else 'Integrated' }}
        processModel.maxProcesses: {{ vhost_data.processes if 'processes' in vhost_data else 1 }}
        processModel.userName: {{ vhost_username }}
        processModel.password: {{ vhost_data.password }}
        processModel.identityType: SpecificUser
        startMode: {{ vhost_data.startmode if 'startmode' in vhost_data else 'OnDemand' }}
    - require:
      - win_servermanager: IIS_Webserver
      - chocolatey: dotnetfx
      - win_iis: {{ vhost }}_website

{%- for vdir, vdir_data in salt['pillar.get']('iis:vdirs:' ~ vhost ~ ':vdirs', {}) %}
{%- set vdir_id = vdir|lower|replace('.','_')|replace('-','_')|replace('/','') %}
{{ vhost }}_vdir_{{ vdir_id }}:
  win_iis.create_vdir:
    - name: {{ vdir }}
{%- if 'site' not in vdir_data -%}
    - site: {{ vhost_apppool }}
{%- else -%}
    - site: {{ vdir_data.site }}
{%- endif -%}
    - source: {{ vdir_data.path }}

{%- if 'source' in vdir_data %}
{{ vhost }}_{{ vdir_id }}_archive:
  archive.extracted:
    - name: "{{ vdir_data.path }}"
    - source: "{{ vdir_data.source }}"
{%- endif %}
{%- endfor %}

{%- endfor %}
