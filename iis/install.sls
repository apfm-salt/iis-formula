# Install IIS role
IIS_WebServer:
  win_servermanager.installed:
    - recurse: True
    - name: Web-Server
{%- if grains.get('IIS_WebServer_Install') == 'complete' %}
  service.running:
    - name: 'W3SVC'
    - require:
      - win_servermanager: IIS_Webserver
{%- endif %}

{%- if grains.get('IIS_WebServer_Install') != 'complete' %}
IIS_WebServer_Reboot:
  system.reboot:
    - only_on_pending_reboot: True
    - require:
      - win_servermanager: IIS_Webserver
    - order: last

IIS_WebServer_Installed:
  grains.present:
    - name: IIS_WebServer_Install
    - value: complete
    - require:
      - system: IIS_WebServer_Reboot
    - order: last
{%- endif %}

chocolatey.bootstrap:
  module.run:
    - chocolatey.bootstrap:
      - force: False
    - unless: "where.exe chocolatey"
