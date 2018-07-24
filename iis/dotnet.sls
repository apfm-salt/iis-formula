# Install .net 4.7 requirement
install_dotnet_4.7_requirements:
  wua.installed:
    - name: KB4019990

# Install via Windows/Windows Update
## Ensure we have .NET 4.7 available
#install_dotnet_4.7:
#  wua.installed:
#    - name: KB3186568

# Install trough repo-ng
dotnet47:
  pkg.installed:
    - require:
      - wua: install_dotnet_4.7_requirements
