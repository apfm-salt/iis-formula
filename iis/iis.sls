# Install IIS role
IIS_Webserver:
  win_servermanager.installed:
    - recurse: True
    - name: Web-Server
  service.running:
    - name: 'World Wide Web Publishing Service'
    - require:
      - win_servermanager: IIS_Webserver
