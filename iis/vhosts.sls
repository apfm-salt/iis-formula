{% from "iis/map.jinja" import iis_settings with context %}

### Deal with IIS vhosts
{%- set webdrive = iis_settings.webroot|regex_replace('^([A-Z]:\\\)', '\1') %}

{%- if webdrive != iis_settings.webroot %}
main_webroot:
  file.directory:
    - name: '{{ iis_settings.webroot }}'
    - user: 'Administrator'
{%- endif %}

{%- for vhost,vhost_data in iis_settings['vhosts'].items() %}

# Create Webroot (createHome: True doesn't appear to be doing this)
{{ vhost }}_webroot:
  file.directory:
    - name: {{ vhost_data.webroot }}
  {%- if 'source' in vhost_data %}
    - require:
      - archive: {{ vhost }}_archive
  {%- endif %}

  {%- if 'source' in vhost_data %}
{{ vhost }}_archive:
  archive.extracted:
    - name: {{ vhost_data.webroot }}
    - source: {{ vhost_data.source }}
    - enforce_toplevel: False
    - skip_verify: {{ vhost_data.verify }}
    {%- if vhost_data.hash != '' %}
    - hash: {{ vhost_data.hash }}
    {%- endif %}
  {%- endif %}

  {%- if grains.get('IIS_WebServer_Install') == 'complete' %}
# Create vhost & application pool
{{ vhost }}_website:
  win_iis.deployed:
    - name: {{ vhost_data.site }}
    - sourcepath: {{ vhost_data.webroot }}
    - apppool: {{ vhost_data.apppool }}
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
    - name: {{ vhost_data.site }}
    - container: Sites
    - require:
      - win_servermanager: IIS_Webserver
      - win_iis: {{ vhost }}_website
  {%- endif %}

  {%- if grains.get('IIS_WebServer_Install') == 'complete' %}
{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost_data.apppool }}
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
