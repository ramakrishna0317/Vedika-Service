node{
   stage('SCM Checkout'){
       git credentialsId: 'git-creds', url: 'https://github.com/shivastunts0327/Service-java.git'
   }
   
   stage('gradle Package'){
     def gradleHome = tool name: 'gradle', type: 'gradle'
     def gradleCMD = "${gradleHome}/bin/gradle"
     sh "${gradleCMD} clean build"
   } 
   
     stage('Creating Dockerfile'){
     sh label: '', script: '''cd /var/lib/jenkins/workspace/Docker.pipeline
     '''
     sh label: '', script: '''cat >Dockerfile <<\'EOF\'
     FROM ubuntu
     COPY ./build/libs/functionhall-service-0.0.1-SNAPSHOT.jar /home/ubuntu/
     RUN apt-get update
     COPY ./build/libs/vedikaservice.sh /usr/local/bin/
     COPY  ./build/libs/vedikaservice.service /etc/systemd/system/
     WORKDIR /home/ubuntu
     RUN apt install software-properties-common apt-transport-https -y
     RUN add-apt-repository ppa:openjdk-r/ppa -y
     RUN apt install openjdk-8-jdk -y
     RUN chmod +x /usr/local/bin/vedikaservice.sh
     RUN apt-get install systemd ''
     EXPOSE 8057
     '''
  }

   stage('Creating vedikaservice.sh'){
sh label: '', script: '''cd /var/lib/jenkins/workspace/Docker.pipeline/build/libs
cat >vedikaservice.sh <<\'EOF\'
#!/bin/sh 
SERVICE_NAME=vedikaservice 
PATH_TO_JAR=/home/ubuntu/functionhall-service-0.0.1-SNAPSHOT.jar
PID_PATH_NAME=/tmp/vedikaservice-pid 
case $1 in 
start)
       echo "Starting $SERVICE_NAME ..."
  if [ ! -f $PID_PATH_NAME ]; then 
       nohup java -jar $PATH_TO_JAR /tmp 2>> /dev/null >>/dev/null &      
                   echo $! > $PID_PATH_NAME  
       echo "$SERVICE_NAME started ..."         
  else 
       echo "$SERVICE_NAME is already running ..."
  fi
;;
stop)
  if [ -f $PID_PATH_NAME ]; then
         PID=$(cat $PID_PATH_NAME);
         echo "$SERVICE_NAME stoping ..." 
         kill $PID;         
         echo "$SERVICE_NAME stopped ..." 
         rm $PID_PATH_NAME       
  else          
         echo "$SERVICE_NAME is not running ..."   
  fi    
;;    
restart)  
  if [ -f $PID_PATH_NAME ]; then 
      PID=$(cat $PID_PATH_NAME);    
      echo "$SERVICE_NAME stopping ..."; 
      kill $PID;           
      echo "$SERVICE_NAME stopped ...";  
      rm $PID_PATH_NAME     
      echo "$SERVICE_NAME starting ..."  
      nohup java -jar $PATH_TO_JAR /tmp 2>> /dev/null >> /dev/null &            
      echo $! > $PID_PATH_NAME  
      echo "$SERVICE_NAME started ..."    
  else           
      echo "$SERVICE_NAME is not running ..."    
     fi     ;;
 esac'''
    }
	
	stage('Creating vedikaservice.service'){
sh label: '', script: '''cd /var/lib/jenkins/workspace/Docker.pipeline/build/libs
cat >vedikaservice.service <<\'EOF\'
[Unit]
 Description = Java Service
 After network.target = vedikaservice.service
[Service]
 Type = forking
 Restart=always
 RestartSec=1
 SuccessExitStatus=143 
 ExecStart = /usr/local/bin/vedikaservice.sh start
 ExecStop = /usr/local/bin/vedikaservice.sh stop
 ExecReload = /usr/local/bin/vedikaservice.sh reload
[Install]
 WantedBy=multi-user.target'''
   }
   
   stage('Back to workspace'){
   sh label: '', script: 'cd /var/lib/jenkins/workspace/Docker.pipeline'
   }
   
   stage('Creating Image'){
   sh label: '', script: 'sudo docker build -t service.jar .'
   }
   
   stage('Back to home/ubuntu'){
   sh label: '', script: 'cd /home/ubuntu'
   }
   
   stage('Creating container'){
  sh label: '', script: 'sudo docker run -i -t -d -p 8050:8057 --name jarcontainer service.jar //bin/bash' 
  }
   
  stage('starting container'){ 
  sh label: '', script: '''sudo docker start jarcontainer
  sudo docker exec -it jarcontainer //bin/bash
  '''
  }
   
   stage('starting vedikaservice'){
   sh label: '', script: '''cd /usr/local/bin
   sh vedikaservice.sh start'''
   }
   
   }
