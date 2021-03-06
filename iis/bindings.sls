{% from "iis/map.jinja" import iis_settings with context %}

{%- if grains.get('IIS_WebServer_Install') == 'complete' %}
  {%- for vhost,vhost_data in iis_settings['vhosts'].items() %}
    {%- for alt_name in vhost_data['alt_names'] %}
{{ alt_name }}_binding:
  win_iis.create_binding:
    - name: {{ alt_name }}
    - site: {{ vhost_data.site }}
    - hostheader: {{ alt_name }}
    - ipaddress: "{{ vhost_data.ip if 'ip' in vhost_data else '*' }}"
    - port: {{ vhost_data.port if 'port' in vhost_data else '80' }}
    - require:
      - win_servermanager: IIS_Webserver
      - file: {{ vhost }}_webroot
      - win_iis: {{ vhost }}_website
    {%- endfor %}
  {%- endfor %}
{%- endif %}
