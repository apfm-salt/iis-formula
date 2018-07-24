# Install .net requirement
#install_dotnet_requirements:
#  wua.installed:
#    - name: KB4019990

# Install via Windows/Windows Update
## Ensure we have .NET 4.7 available
#install_dotnetfx:
#  wua.installed:
#    - name: KB3186568

# Install trough repo-ng
#dotnetfx:
#  pkg.installed:
#    - version: {{ salt['pillar.get']('iis:dotnetfx:version')}}
#    - require:
#      - wua: install_dotnet_requirements

# Install trough chocolatey
dotnetfx:
  chocolatey.installed:
    - name: dotnetfx
    - version: {{ salt['pillar.get']('iis:dotnetfx:version', '4.7.2') }}
