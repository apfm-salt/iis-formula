### Deal with IIS vhosts
{%- set webroot = salt['pillar.get']('iis:webroot', 'c:\inetpub\sites') %}
{%- set webdrive = webroot|regex_replace('^([A-Z]:\\\)', '\1') %}

{%- if webdrive != webroot %}
main_webroot:
  file.directory:
    - name: '{{ webroot }}\'
    - user: 'Administrator'
{%- endif %}

{%- for vhost,vhost_data in salt['pillar.get']('iis:vhosts', {}).items() %}
  {%- set vhost_site = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':site', vhost ) %}
  {%- set vhost_apppool = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apppool', vhost_site ) %}
  {%- set vhost_webroot = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':webroot', webroot ~ '\\' ~ vhost_apppool ) %}
  {%- set vhost_hash = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':hash', '') %}
  {%- set vhost_skip_verify = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':skip_verify', True) %}


# Create Webroot (createHome: True doesn't appear to be doing this)
{{ vhost }}_webroot:
  file.directory:
    - name: {{ vhost_webroot }}
  {%- if 'source' in vhost_data %}
    - require:
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

  {%- if grains.get('IIS_WebServer_Install') == 'complete' %}
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
  {%- endif %}

  {%- if grains.get('IIS_WebServer_Install') == 'complete' %}
{{ vhost }}_site_settings:
  win_iis.container_setting:
    - name: {{ vhost_site }}
    - container: Sites
    - require:
      - win_servermanager: IIS_Webserver
      - win_iis: {{ vhost }}_website
  {%- endif %}

  {%- if grains.get('IIS_WebServer_Install') == 'complete' %}
{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost_apppool }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ vhost_data.pipelinemode if 'pipelinemode' in vhost_data else 'Integrated' }}
        processModel.maxProcesses: {{ vhost_data.processes if 'processes' in vhost_data else 1 }}
        startMode: {{ vhost_data.startmode if 'startmode' in vhost_data else 'OnDemand' }}
    - require:
      - win_servermanager: IIS_Webserver
      - win_iis: {{ vhost }}_website
  {%- endif %}
{%- endfor %}
