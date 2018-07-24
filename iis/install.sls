# Install IIS role
IIS_Webserver:
  win_servermanager.installed:
    - recurse: True
    - name: Web-Server
  service.running:
    - name: 'W3SVC'
    - require:
      - win_servermanager: IIS_Webserver
