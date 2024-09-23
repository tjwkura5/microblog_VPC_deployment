# Microblog Deployed to EC2 on Custom VPC

---


## Purpose

In our previous workload, we were introduced to provisioning our own infrastructure, but it was far from an optimal system. In this workload, we will address some of the issues from workload 3. Specifically, we will create a custom VPC and separate EC2 instances for our Jenkins server, web server (running Nginx), application server (running our Flask app), and a monitoring server. Additionally, we will set up public and private subnets to separate our application into tiers.

Let's get started!

## Clone Repository

Clone [this](https://github.com/kura-labs-org/C5-Deployment-Workload-4) github repository to your Github account. The steps for this have been outlined in the past two workloads. If you get stuck you can refer back to workload 2 [here](https://github.com/tjwkura5/retail-banking-app-deployed-elastic-beanstalk-2).

## Custom VPC
In this section we will go over the steps for creating a custom VPC. Our VPC will have a one availability zone (AZ), a public and private subnet and a NAT Gateway.

**Step 1: Create a Custom VPC**

1. Navigate to the VPC Dashboard:

    *  In the AWS Console, search for "VPC" and click on "VPC" under "Networking & Content Delivery".
Click on "Create VPC":

2. In the VPC dashboard, click the "Create VPC" button.

3. VPC Settings:

    * Name tag: Enter a name for your VPC (e.g., MyCustomVPC).
    * IPv4 CIDR block: Enter an IP range (e.g., 10.0.0.0/16).
    * IPv6 CIDR block: Leave this empty unless you need IPv6.
    * Tenancy: Choose "Default" u
    * Enable DNS hostnames: Select "Yes" (ensures EC2 instances get public DNS names).
    * Enable DNS resolution: Select "Yes" (enables resolving domain names).

4. Click "Create VPC".

**Step 2: Create Subnets**

1. Create a Public Subnet:

    * On the VPC Dashboard, go to "Subnets" and click on "Create subnet".
    * Name tag: Enter a name (e.g., PublicSubnet).
    * VPC ID: Choose the VPC you just created (e.g., MyCustomVPC).
    * Availability Zone: Select one Availability Zone (e.g., us-east-1a).
    * IPv4 CIDR block: Enter a subnet IP range (e.g., 10.0.1.0/24 for the public subnet).
    * Enable auto-assign public IPv4 address: Check this box (this ensures that EC2 instances in this subnet get a public IPv4 address automatically).
    * Click "Create subnet".

2. Create a Private Subnet:

    * Repeat the steps to create a second subnet for the private subnet.
    * Name tag: Enter a name (e.g., PrivateSubnet).
    * VPC ID: Choose the same VPC.
    * Availability Zone: Select the same Availability Zone (e.g., us-east-1a).
    * IPv4 CIDR block: Enter a different subnet IP range (e.g., 10.0.2.0/24 for the private subnet).
    * Click "Create subnet".

**Step 3: Create and Attach an Internet Gateway (for Public Subnet)**

1. Create Internet Gateway:
    * In the VPC Dashboard, go to "Internet Gateways" and click on "Create internet gateway".
    * Name tag: Enter a name (e.g., MyInternetGateway).
    *  Click "Create internet gateway".
2. Attach Internet Gateway to VPC:
    * After creating the internet gateway, select it and click "Actions" → "Attach to VPC".
    * Choose the VPC you created (e.g., MyCustomVPC).

**Step 4: Modify Route Table for Public Subnet**

1. Create a Route Table:
    * In the VPC Dashboard, go to "Route Tables" and click "Create route table".
    * Name tag: Enter a name (e.g., PublicRouteTable).
    * VPC: Choose your VPC.
    * Click "Create route table".
2. Add a Route to the Internet:
    * Select the public route table you just created.
    * Under the "Routes" tab, click "Edit routes" → "Add route".
    * Destination: 0.0.0.0/0 (for all IPv4 traffic).
    * Target: Select "Internet Gateway" and choose the one you created (e.g., MyInternetGateway).
    * Click "Save routes".
3. Associate Public Subnet with Route Table:
    * Under the "Subnet associations" tab of the route table, click "Edit subnet associations".
    * Select the public subnet you created earlier (e.g., PublicSubnet) and click "Save".

**Step 5: Create a NAT Gateway (for Private Subnet)**

1. Create an Elastic IP (EIP):

    *  In the VPC Dashboard, go to "Elastic IPs" and click "Allocate Elastic IP address".
    * Click "Allocate" to get a new EIP.

2. Create NAT Gateway:
    * In the VPC Dashboard, go to "NAT Gateways" and click "Create NAT Gateway".
    * Subnet: Select the public subnet (PublicSubnet).
    * Elastic IP Allocation ID: Select the Elastic IP address you just created.
    * Click "Create NAT Gateway".

3. Modify Route Table for Private Subnet:
    * In the VPC Dashboard, go to "Route Tables" and select the private route table.
    * Under "Routes", click "Edit routes" → "Add route".
    * Destination: 0.0.0.0/0.
    * Target: Select "NAT Gateway" and choose the one you created.
    * Click "Save routes".

## Jenkins Server

**Setting Up the CI Server (Jenkins):**

In the Default VPC, create an Ubuntu EC2 instance (t3.micro) named "Jenkins". Be sure to configure the security group to allow for SSH and HTTP traffic in addition to the ports required for Jenkins and any other services needed (Security Groups can always be modified afterward). We have gone over this step in the past two workloads so it should be familar if you need a refresher you can take a look at the instructions [here](https://github.com/kura-labs-org/AWS-EC2-Quick-Start-Guide/blob/main/AWS%20EC2%20Quick%20Start%20Guide.pdf).

We will use the Jenkins installation script we created in workload 3 to install Jenkins. We will keep our Jenkinsfile mostly the same as in the previous workload, except for the OWASP FS SCAN stage, and we will leave the deploy stage blank for now.

**The OWASP FS SCAN Stage**

In the last workload, we signed up for and created an NVD API key to speed up our dependency check stage. We were adding the nvd_api_key directly to the pipeline script, which is a security risk. This time, we will add our nvd_api_key to Jenkins using the Manage Credentials feature. 

**Step 1: Access Jenkins Dashboard**
1. Login to Jenkins:
    * Open Jenkins in your web browser and log in using your credentials.
2. Navigate to the Jenkins Dashboard.

**Step 2: Access Manage Jenkins**
1. From the Jenkins Dashboard, click on "Manage Jenkins" in the left-hand menu.
2. Scroll down to the "Security" section and click on "Manage Credentials".

**Step 3: Select Credentials Domain**
1. On the Manage Credentials page, select the (global) domain under "Stores scoped to Jenkins". If you want to scope the credential to a specific domain or folder, select the appropriate one.
2. In the (global) domain, click on "Add Credentials" on the left side.

**Step 4: Add nvd_api_key**
1. In the Kind dropdown, select "Secret text" (since the nvd_api_key is a secret value).
2. Secret: Enter your nvd_api_key in the text box.
3. ID: (Optional) You can provide a specific ID for easier reference in pipelines (e.g., nvd_api_key). If left empty, Jenkins will auto-generate one.
4. Description: Provide a description (e.g., "NVD API Key for OWASP Scans").
5. Click "OK" to save the credentials.

**Step 5: Using nvd_api_key in a Jenkins Pipeline**
1. Open your Jenkinsfile.
2. In the OWASP FS SCAN stage, you can reference the API key like this:

    ```
        stage('OWASP FS SCAN') {
            steps {
                // Use the withCredentials step to inject the NVD API key into the environment
                withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_API_KEY')]) {
                    dependencyCheck additionalArguments: "--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_API_KEY}", 
                                   odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
    ```

## Create our App and Web Server

1. Create an EC2 t3.micro called "Web_Server" In the PUBLIC SUBNET of the Custom VPC, and create a security group with ports 22 and 80 open.

2. Create an EC2 t3.micro called "Application_Server" in the PRIVATE SUBNET of the Custom VPC, and create a security group with ports 22 and 5000 open. Make sure you create and save the key pair to your local machine.

3. SSH into the "Jenkins" server and run ssh-keygen. Copy the public key that was created and append it into the "authorized_keys" file in the Web Server.

4. Test the connection by SSH'ing into the 'Web_Server' from the 'Jenkins' server. This will also add the web server instance to the "list of known hosts".

5. In the Web Server, install NginX. We did this in workload 3 you can take a look [here](https://github.com/tjwkura5/microblog_VPC_deployment/tree/main).

6. Modify the "sites-enabled/default" file so that the "location" section reads as below:

    ```
    location / {
        proxy_pass http://<app_server_private_IP>:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    ```

## VPC Peering

In the "Create Our App and Web Server" section, we are testing the connection between our Jenkins and web server by SSH'ing into the 'Web_Server' from the 'Jenkins' server. However, we are using public IP addresses to do so. The issue with using public IP addresses is that they can change. In this section, we will set up VPC peering. VPC peering allows you to connect two Virtual Private Clouds (VPCs) so that they can communicate with each other privately using private IP addresses.

**Initiate VPC Peering Request**
1. Open the VPC Dashboard:
    * Navigate to VPC by searching for it in the services search bar.
2. Create the Peering Connection:
    * In the VPC Dashboard, on the left panel, choose Peering Connections under VPC.
    * Click Create Peering Connection.
3. Configure the Peering Connection:
    * Give the peering connection a name.
    * Select the Requester VPC (default VPC).
    * Select the Accepter VPC:
        * Select the second VPC from the dropdown.
4. Choose Peering Connection Type:
    * Select intra-region (same region).
5. Create Peering Request:
    * After filling out the details, click Create Peering Connection.
    * A request will be initiated to the Accepter VPC (in the same or a different account).

**Accept the VPC Peering Request**
1. Accept the Request:
    * Go to the VPC Dashboard
    * In the Peering Connections section, select the pending peering connection.
    * Click Actions and then Accept Request.
2. Verify the Peering Connection:
    * After acceptance, the peering connection status should change to Active.

**Modify the Route Tables for Both VPCs**
1. Update Route Tables:
    * In both the Requester and Accepter VPCs, you’ll need to modify the route tables so that instances in one VPC can communicate with the other.
2. For the Requester VPC:
    * Go to Route Tables in the VPC Dashboard.
    * Select the route table for the VPC subnet(s) that need access to the Accepter VPC.
    * Under Routes, click Edit Routes, then click Add Route.
    * In the Destination field, enter the CIDR block of the Accepter VPC.
    * In the Target field, select the Peering Connection you created.
    * Click Save routes.
3. For the Accepter VPC:
    * Repeat the same process, but this time modify the route table in the Accepter VPC and add a route to the Requester VPC’s CIDR block.

**Test the Peering Connection**

Once the routing is in place, test the connection by trying to communicate between instances in the two VPCs.

* SSH into the 'Web_Server' from the 'Jenkins' server using the web server private IP addres. 

## System Diagram

![sys_diagram](Diagram.jpg)