{%- if grains.get('IIS_WebServer_Install') == 'complete' %}
  {%- for apppool in salt['pillar.get']('iis:apppools', []) %}
{{ apppool }}_apppool:
  win_iis.create_apppool:
    - name: {{ apppool }}
    - require:
      - win_servermanager: IIS_Webserver
  {%- endfor %}
{%- endif %}
