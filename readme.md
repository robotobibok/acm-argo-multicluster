testing

start z pierwszego klastra z zainstalowanym acm:
oc apply -k bootstrap/namespaces
oc apply -k bootstrap/gitops-operator

zeby mozna bylo konfigurowac caly klaster, uprawnienia:
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops

mozna sie bawic bardziej detalicznie:
one or more objects failed to apply, reason: secrets is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot create resource "secrets" in API group "" in the namespace "openshift-config". Retrying attempt #5 at 8:17PM.


kubeseal --format yaml --controller-namespace sealed-secrets <htpasswd-secret.yaml > htpasswd-sealed.yaml


po zainstalowaniu nie dodaje do ACM:  
Failed sync attempt to a2717a708848ed84efd1fab7f4e047a5fda55f0d: one or more objects failed to apply, reason: admission webhook "clusterdeploymentvalidators.admission.hive.openshift.io" denied the request: ClusterDeployment.hive.openshift.io "dev" is invalid: spec.installed: Invalid value: false: cannot make uninstalled once installed

diff z managedcluster:
    name: dev
    name: dev.eskom.demo
diff z clusterdeployment
  installed: true
  installed: false


Failed sync attempt to 68f1275f9eeaee8a785dbd9878ad613b3297abd4: one or more objects failed to apply, reason: admission webhook "machinepoolvalidators.admission.hive.openshift.io" denied the request: MachinePool.hive.openshift.io "dev-infra" is invalid: metadata.name: Invalid value: "dev-infra": name must be ${CD_NAME}-${POOL_NAME}, where ${CD_NAME} is the name of the clusterdeployment and ${POOL_NAME} is the name of the remote machine pool,admission webhook "machinepoolvalidators.admission.hive.openshift.io" denied the request: MachinePool.hive.openshift.io "dev-worker" is invalid: metadata.name: Invalid value: "dev-worker": name must be ${CD_NAME}-${POOL_NAME}, where ${CD_NAME} is the name of the clusterdeployment and ${POOL_NAME} is the name of the remote machine pool