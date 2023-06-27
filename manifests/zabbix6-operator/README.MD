# Zabbix Operator
Podane repozytorium zawiera definicje dla instalacji oraz konfiguracji Zabbix Operator w wersji 6 dla platformy Openshit Container Platform w wersji 4.12

## Instalacja
W ramach instalacji należy wskazać w pliku konfiguracji klastra odpowiednie katalogi odwołujące się do manifestów zabbix'a

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
- ../../manifests/zabbix6-operator/
```

## Konfiguracja
Konfiguracje należy przeprowadzić po stronie platformy Openshift jak i po stronie zabbix'a. 

### Konfiguracja Openshift
W ramach instalacji zabbix'a na platformie Openshift należy zdefiniować serwer do którego będą przesyłane dane z zabbix agent w pliku:

```yaml
spec:
  buffer_size: 100
  refresh_active_checks: 120
  timeout: 3
  host_interface: ''
  metadata_item: 'system.uname'
  server_host: <host zabbix server lub proxy>
```

### Konfiguracja Zabbix
Po zdeployowaniu manifestów na klaster, należy przeprowadzić konfiguracje po stronie zabbix'a:

* Utworzyć grupę hostów dla węzłów Openshift
* Zaimportować Template(Jeżeli nie istnieje) [Template OS Linux by Zabbix agent active](https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/os/linux_active?at=refs%2Fheads%2Frelease%2F5.0)
* Utworzyć akcje z autorejestracją dla węzłów Openshift z operacjami dla linkowania do podanej wyżej grupy oraz template'a