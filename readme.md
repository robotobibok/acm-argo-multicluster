problem:  deploy + management wielu klastrow OCP w modelu gitops  
uzyte narzędzia: Red Hat Advcanced Cluster Management, ArgoCD (Red Hat Gitops), Sealed Secrets  

```bash
acm-argo-multicluster
├── applications              # definicje aplikacji Argo per klaster
│   ├── infra.eskom.demo    
│   └── dev.eskom.demo
├── bootstrap                 # punkt startowy, argocd-apps wskazuje na powyzszy
│   ├── argocd-apps
│   ├── gitops-operator
│   ├── namespaces
│   └── sealed-secrets
├── cluster-config            # agreguje konfiguracje z folderu manifests, tu wskazuje folder applications
│   ├── infra.eskom.demo
│   ├── dev.eskom.demo
│   └── test.eskom.demo
├── cluster-deploy            # agreguje informacje o deploymencie klastrow z folderu managed-clusters, tu wskazuje folder applications
│   ├── dev.eskom.demo
│   └── test.eskom.demo
├── managed-clusters          # wszystko potrzebne do stworzenia klastrow z poziomu ACM
│   ├── dev.eskom.demo
│   │   └── secrets
│   └── test.eskom.demo
│       └── secrets
└── manifests                 # zbiory konfiguracji klastrow
    ├── gitops-operator
    ├── namespaces
    ├── oauth-htpasswd
    ├── rbac
    ├── registry
    │   ├── base
    │   └── overlays
    │       └── rwo
    └── sealed-deploy

```


- deploy z bastiona, user ocp  
``export KUBECONFIG=/home/ocp/infra.eskom.demo/auth/kubeconfig``

start z pierwszego klastra (infra)
```
oc apply -k bootstrap/namespaces
oc apply -k bootstrap/acm-operator
oc apply -k bootstrap/gitops-operator
oc apply -k bootstrap/sealed-secrets
oc apply -k bootstrap/argocd-apps 
```
- pozniej juz zmiany bezposrednio w repo, dodawanie aplikacji w ``applications/`` po czym odswiezenie definicji aplikacji w ACM, ktory nanosi juz wszystko na Argo, ktore powoluje klastry z ACM

- uprawnienia admina dla Argo:
``oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops``

- sekrety musza byc wygenerowane ze wskazaniem odpowiedniego ns, na bastion sealed_secrets są wszystkie. W przypadku reinstall infra/zmiany klucza trzeba je przegenerować
``kubeseal --format yaml --controller-namespace sealed-secrets <htpasswd-secret.yaml > htpasswd-sealed.yaml``  

- po uruchomieniu wszyskiego na klastrze infra, acm nanosi sealed-secret na klastry, ktore uruchomi sie za pomoca konfiguracji z manifests/gitops-config (aplikacja w acm) - gitops cluster etc  

- po instalacji sealed secrets na zarzadzanym klastrze, trzeba wygenerowac w overlay dla kazdego klastra ``manifests/oauth-htpasswd/overlays/dev/htpasswd-secret.yaml``, zeby kontroler sealed mogl je odpalic  

- zalozenie jest takie, ze mastery sa na datastore ssd, workery i infry na hdd, inaczej sa problemy z dzialaniem etcd. dlatego nie powolujemy machineset z acm, tylko powolujemy maly klaster na ssd, pozniej argo dodajemy machinesety dla worker/infra na ssd. klaster dev caly jest na hdd. Dlatego po instalacji trzeba ustawic aktualny cluster-id w ``manifests/machine-set/test.eskom.demo``
---
architektura managed clusters  
infra: 3xmaster, 5xworker
- acm
- gitops
- odf ? 
- quay ?  

dev: 3xmaster, 2xworker  
test: 3xmaster, 3xinfra, 3xworker  
prod: 3xmaster, 3xinfra, 3xworker  
? dis: jakis klaster disconnected  
? sno: all-in-one baremetal  

---
todo
- przeniesienie routerow na infra
- uruchomienie registry na infra
- htpasswd admin/pip
- dodanie polityk acm
- etcd szyfrowanie
- 

maybe
- bardziej granularne uprawnienia dla Argo
- maly klaster disconnected
- baremetal z acm


---
bledy   

uprawnienia dla Argo:
``one or more objects failed to apply, reason: secrets is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot create resource "secrets" in API group "" in the namespace "openshift-config". Retrying attempt #5 at 8:17PM.``

po zainstalowaniu nie dodaje do ACM:  
``Failed sync attempt to a2717a708848ed84efd1fab7f4e047a5fda55f0d: one or more objects failed to apply, reason: admission webhook "clusterdeploymentvalidators.admission.hive.openshift.io" denied the request: ClusterDeployment.hive.openshift.io "dev" is invalid: spec.installed: Invalid value: false: cannot make uninstalled once installed``

```
diff z managedcluster:  
    name: dev  
    name: dev.eskom.demo  
diff z clusterdeployment  
  installed: true  
  installed: false  
```

```
Failed sync attempt to 68f1275f9eeaee8a785dbd9878ad613b3297abd4: one or more objects failed to apply, reason: admission webhook "machinepoolvalidators.admission.hive.openshift.io" denied the request: MachinePool.hive.openshift.io "dev-infra" is invalid: metadata.name: Invalid value: "dev-infra": name must be ${CD_NAME}-${POOL_NAME}, where ${CD_NAME} is the name of the clusterdeployment and ${POOL_NAME} is the name of the remote machine pool,admission webhook "machinepoolvalidators.admission.hive.openshift.io" denied the request: MachinePool.hive.openshift.io "dev-worker" is invalid: metadata.name: Invalid value: "dev-worker": name must be ${CD_NAME}-${POOL_NAME}, where ${CD_NAME} is the name of the clusterdeployment and ${POOL_NAME} is the name of the remote machine pool
```


debug klusterletaddon
```[ocp@bastion ~]$ oc -n multicluster-engine logs -l app=managedcluster-import-controller-v2 --tail=-1  
2023-04-03T19:13:14.350304389Z  INFO    importconfig-controller Reconciling managed cluster import secret       {"Request.Name": "dev.eskom.demo"}
I0403 19:13:14.428436       1 event.go:285] Event(v1.ObjectReference{Kind:"Deployment", Namespace:"multicluster-engine", Name:"managedcluster-import-controller-v2", UID:"274b5e9f-b74f-454e-b636-e573238d346b", APIVersion:"apps/v1", ResourceVersion:"", FieldPath:""}): type: 'Warning' reason: 'ServiceAccountCreateFailed' Failed to create ServiceAccount/dev.eskom.demo-bootstrap-sa -n dev.eskom.demo: namespaces "dev.eskom.demo" not found
```

rozwalila sie konfiguracja klastra, dodane reczne prunowanie
```
rpc error: code = Unknown desc = Manifest generation error (cached): `kustomize build .cluster-config/infra.eskom.demo` failed exit status 1: Error: accumulating resources: accumulation err='accumulating resources from '../../manifests/oauth-htpasswd': '.manifests/oauth-htpasswd' must resolve to a file': recursed accumulation of path '.manifests/oauth-htpasswd': accumulating resources: accumulation err='accumulating resources from 'htpasswd-oauth.yaml': missing metadata.name in object {{config.openshift.io/v1 OAuth} {{ } map[] map[argocd.argoproj.io/sync-options:Prune=false]}}': got file 'htpasswd-oauth.yaml', but '.manifests/oauth-htpasswd/htpasswd-oauth.yaml' must be a directory to be a root
```

Platform credentials failed authentication check: POST https://vcenter.elab.local/rest/com/vmware/cis/session: 503 Service  
https://blogs.vmware.com/performance/2022/07/endpoint-limits-for-concurrent-rest-requests-from-vcenter-apis.html
```
/var/log/vmware/vapi/endpoint
2023-04-07T22:03:05.565Z | WARN  | sso3                      | BaseSessionImpl                | User sessions count is limited to 550. Existing sessions are 550 for user ocp@VSPHERE.LOCAL. Please retry the login operation

zmiana uzytkownika nic nie dala  
2023-04-08T09:54:20.910Z | WARN  | sso8                      | BaseSessionImpl                | User sessions count is limited to 550. Existing sessions are 550 for user ocpdev@VSPHERE.LOCAL. Please retry the login operation

nie znalazlem jak to zmienic lepiej:
vi /etc/vmware-vapi/endpoint.properties
  session.maxSessionCount=2000 # bylo 1000
  session.maxSessionsPerUser=1550 # bylo 550
service-control --restart vmware-vapi-endpoint
```
t

alertmanager
```
[ocp@bastion infra]$ oc -n openshift-monitoring create secret generic alertmanager-main --from-file=alertmanager.yaml --dry-run -o=yaml > secret.yaml
W0426 11:51:21.875263   74769 helpers.go:663] --dry-run is deprecated and can be replaced with --dry-run=client.
[ocp@bastion infra]$ kubeseal --format yaml --controller-namespace sealed-secrets <secret.yaml > secret-sealed.yaml
```

odf  
recznie enable w konsoli ocp dodatku do odf //TODO
reczne labelowanie: //TODO
```
[ocp@bastion ~]$ oc label node infra-5lgrz-worker-zv7s5 cluster.ocs.openshift.io/openshift-storage="" --overwrite=true
node/infra-5lgrz-worker-zv7s5 labeled
[ocp@bastion ~]$ oc label node infra-5lgrz-worker-hxb8z cluster.ocs.openshift.io/openshift-storage="" --overwrite=true
node/infra-5lgrz-worker-hxb8z labeled
[ocp@bastion ~]$ oc label node infra-5lgrz-worker-dr6zz cluster.ocs.openshift.io/openshift-storage="" --overwrite=true
node/infra-5lgrz-worker-dr6zz labeled
```

do powyzszych 4-> 12vcpu, 16 -> 24GB bo mdf i osd nie wstawaly

test
