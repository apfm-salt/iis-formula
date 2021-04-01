{%- from "iis/map.jinja" import iis_settings with context %}

{%- for vhost,vhost_data in iis_settings['vhosts'].items() %}
  {%- for app,app_data in vhost_data['apps'].items() %}

    {%- if 'source' in app_data %}
{{ vhost }}_{{ app_data.id }}_archive:
  archive.extracted:
    - name: {{ app_data.path }}
    - source: {{ app_data.source }}
    - enforce_toplevel: False
    - skip_verify: {{ app_data.verify }}
        {%- if app_data.hash != '' %}
    - hash: {{ app_data.hash }}
        {%- endif %}
      {%- endif %}

    {%- if grains.get('IIS_WebServer_Install') == 'complete' %}
{{ vhost }}_app_{{ app_data.id }}:
  win_iis.create_app:
    - name: {{ app_data.name }}
    - site: {{ app_data.site }}
    - apppool: {{ app_data.pool }}
    - sourcepath: {{ app_data.path }}
    - require:
      - win_servermanager: IIS_Webserver
      {%- if 'source' in app_data %}
      - archive: {{ vhost }}_{{ app_data.id }}_archive
      {%- endif %}
    {%- endif %}

  {%- endfor %}
{%- endfor %}
