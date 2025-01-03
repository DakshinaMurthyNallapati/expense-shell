#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
        then
            echo -e "$2.. $R FAILURE $N"
            exit 1
        else
            echo -e "$2..$G SUCCESS $N"
    fi

}

CHECK_ROOT(){

    if [ $USERID -ne 0 ]
        then 
            echo "Error:: You need sudo access to execute this script"
            exit 1 #other than 0
    fi

    }

echo "Script started executing at : $TIMESTAMP" &>>$LOG_FILE_NAME


CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nodejs 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Insalling nodejs"

id expense &>>$LOG_FILE_NAME
    if [ $? -ne 0 ]
        then
            useradd expense &>>$LOG_FILE_NAME
            VALIDATE $? "Adding  expense user"
        else 
            echo -e "expense user already exists... $Y SKIPPING $N"
    fi

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"


curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend server files"

cd /app

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependecies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

# Prepare MySql Schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySql Client"

mysql -h mysql.dakshina.cloud -u root -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions database and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon reloaded"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabled backend server"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Started backend"

