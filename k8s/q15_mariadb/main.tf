# ---------------------------------------------------------------------------
# Q15: PersistentVolume Restoration (MariaDB)
# ---------------------------------------------------------------------------
# Setup: Create the mariadb-pv PersistentVolume with Retain policy and
#        place the mariadb-deployment.yaml template at ~/mariadb-deployment.yaml
#        on the student's workstation (via local_file).
#
# The MariaDB Deployment is intentionally NOT deployed — it has been
# "deleted by mistake" per the question scenario.
#
# Task:  Students must:
#        1. Create a PVC named "mariadb" (250Mi) that binds to mariadb-pv.
#        2. Edit ~/mariadb-deployment.yaml to reference the new PVC.
#        3. Apply the Deployment.

# ---------------------------------------------------------------------------
# PersistentVolume
# ---------------------------------------------------------------------------

resource "kubernetes_persistent_volume_v1" "mariadb_pv" {
  metadata {
    name = "mariadb-pv"
  }

  spec {
    capacity = {
      storage = "300Mi"
    }

    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/tmp/mariadb-data"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# mariadb-deployment.yaml template written to the local filesystem.
# Students edit this file and apply it as part of the task.
# ---------------------------------------------------------------------------

resource "local_file" "mariadb_deployment_template" {
  filename = pathexpand("~/mariadb-deployment.yaml")
  content  = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mariadb
      namespace: mariadb
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: mariadb
      template:
        metadata:
          labels:
            app: mariadb
        spec:
          containers:
            - name: mariadb
              image: mariadb:latest
              env:
                - name: MYSQL_ROOT_PASSWORD
                  value: "password"
              ports:
                - containerPort: 3306
              volumeMounts:
                - name: mariadb-storage
                  mountPath: /var/lib/mysql
              resources:
                requests:
                  memory: "256Mi"
                  cpu: "100m"
                limits:
                  memory: "512Mi"
                  cpu: "200m"
          volumes:
            - name: mariadb-storage
              persistentVolumeClaim:
                # TODO: Update claimName to the PVC you create in Q15
                claimName: mariadb-pvc
  YAML
}
