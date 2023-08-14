# Notes Application Deployments
This repositroy features a simple notes app and two methods of deployment for dev and production.
* Adjustments for taskdef.json still need to be added.
## App
The app is a simple notes app made using Flask. Users first must create an account. Once their account is created and they have logged on, they can create and delete different notes in their account.
 ## Dev
 The development envrioment uses Terraform to create a VPC, RDS and autoscaling group. For secutiry, the RDS is on a private subnet. Thet autoscaling group uses load balancing and cloud watch metrics alarm. If the average CPU usage in an instance, another ec2 instance is deployed. If the average CPU usage then drops, the autoscaling group scales down.
 To use, the correct github credentials (username, repository name, access token) must be inserted into the user data file found in /terraform-asg.

 ## Production
 The production envrionemt makes use of containers hosted on an ECS service. Using dynamic port mapping and a CI/CD pipeline (GitHub actions), updated containers will be deployed into the service upon pushing to the main branch of this repository. Once the updated containers have been deployed and are healthy, they will be added to the target group of the load balancer, and the old cotainers will be drained. This blue/green deployment strategy allows for 0 downtime. It can also be made highly scalable by increasing the number/size of the EC2 instances running the containers to allow for the deployment of more containers, and then increasing the desire container count. This can be done by adjusting the desired count/ capacity of instances and the cluster service found in /terraform-ecs/module/cluster/main.tf.
 
 Monitoring has also been set up with Prometheus. Prometheus is hosted on its own instance and will scrape the intances in the ECS cluster for metrics. The dns name of the Prometheus instance will be one of the outputs in the second ***terraform apply*** command. Using this, a monitorting dashboard can be set up using Grafana. Below is one that is currently in use:
 ![Grafana-Dashboard](./Grafana%20dashboard.PNG)

Prerequisites:
* Have Terraform and Docker Desktop installed
* Access to an AWS account along with an access key and secret access key

Instructions for use of the production evnironemnt:
* After forking this repository on GitHub, you will need go to Setting -> Secrets and variables -> Actions
* Create two ***New repository secret***s. Once shall be ***AWS_ACCESS_KEY_ID*** (with the value of your AWS Acess Key) and the other ***AWS_SECRET_ACCESS_KEY*** (value of your AWS Secret Access Key).
* Go into the terraform-ecs directory
* Run terraform init
* Comment out the ***create-cluster*** module in ***main.tf*** and the bottom 3 outputs in ***output.tf***
* Run terraform apply. You will need the outputs once this has finished.

* In ***/website-code/website/__init.py__***, change the database endpoint on line 13 after the ***@***, keeping the port and dbname, to the rds-endpoint output.

i.e 'postgresql://postgres:AWSdatabase123@**terraform-20230802144309668000000001.cr3ferbojjxx.eu-west-2.rds.amazonaws.com**:5432/mydb'

* In ***/wesbite-code/*** run ***docker build -t nodes-deployment***
* Run ***docker image ls*** to find the image id
* To push the Docker image to AWS ECR, follow the steps at ***https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html***. Use the ecr-repositroy output from the Terraform apply for ***aws_account_id.dkr.ecr.us-west-2.amazonaws.com/my-repository:tag***.


* In ***/taskfed.json***, change ***image*** to the ecr-repository output.
* Uncomment out the ***create-cluster*** module in /terraform-ecs/main.tf and the bottom three outputs in ***output.tf***
* Run terraform apply.

In the outputs, the ***elb-dns*** is the address of the load balancer used to access the notes app.

Use the ***monitoring-address***:9090 to access the monitoring of the cluster.

### Notes on monitoring 

By using ECS, if any instances/ tasks fail, new ones will be deployed automatically. The use of blue/green deployment for updates also means new clusters (and possibly instances) will be deployed and old ones drained. This means the that the IP addresses will change. The load balancer will handle cliet traffic automatically but the monitoring also needs to change which instance/ tasks it is scraping dynamically. This is made possible by configuring prometheus to get the instance addresses that are in the vpc created. However, as the prometheus instance is in the same vpc, it is also scrpaing itself. As the IP of this instance is not known during its creation, the prometheus config must be updated after.

By using SSH to access the monitoring instance, navigate to ***/etc/prometheus*** and change ***prometheus.yml*** to include the following:
```
relabel_configs:
      - source_labels: [__address__]
        regex: private-ip:9779
        action: drop
```
The private-ip will be the output named ***monitoring-ip***

If you run ***cat prometheus.yml*** it should look similar to the followng:
``````
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'
scrape_configs:
  - job_name: 'instances'
    ec2_sd_configs:
      - region: 'eu-west-2'  
        port: 9779
        filters: 
          - name: 'vpc-id'
            values:
              - vpc-0123456789
    relabel_configs:
      - source_labels: [__address__]
        regex: 10.0.1.4:9779
        action: drop

