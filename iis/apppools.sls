{% from "iis/map.jinja" import iis_settings with context %}

{%- if grains.get('IIS_WebServer_Install') == 'complete' %}
  {%- for apppool in iis_settings['apppools'] %}
{{ apppool }}_apppool:
  win_iis.create_apppool:
    - name: {{ apppool }}
    - require:
      - win_servermanager: IIS_Webserver
  {%- endfor %}
{%- endif %}
