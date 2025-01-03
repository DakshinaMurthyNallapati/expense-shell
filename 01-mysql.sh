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

dnf install mysql-server -y &>>$LOG_FILE_NAME
echo "MySQL-server installation started at : $TIMESTAMP"
VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld
echo "Enabling MySQL Server started at : $TIMESTAMP"
VALIDATE $? "Enabling MySQL Server"

systemctl start mysqld
echo "MySQL Server starting : $TIMESTAMP"
VALIDATE $? "Starting MySQL Server"

mysql -h mysql.dakshina.cloud -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
    then
        echo "MySql root password not setup" &>>$LOG_FILE_NAME
        mysql_secure_installation --set-root-pass ExpenseApp@1
        VALIDATE $? "Setting root password"
    else 
        echo -e "MySQL Root password already setup.... $Y SKIPPING $N"
fi



