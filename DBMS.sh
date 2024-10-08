#!/bin/bash

#----------------------- Start Utils Fuctions---------------------------------------

function validateParamName {
    
    if [ -z "$1" ]
    then
        echo "The name field cannot be left empty"
        return 1
    elif [[ "$1" =~ ^[0-9] ]]
    then
        echo "Name should not begin with a number"
        return 1
    elif [[ "$1" = *" "* ]]
    then
        echo "Name Shouldn't Have Spaces"
        return 1
    elif [[ "$1" =~ [^a-zA-Z0-9_] ]]
    then
        echo "Name Shouldn't Have Special Characters"
        return 1
    fi
    
}

#$1 -> Value
#$2 -> datatype
function validateDataType {
    
    if [ -z "$1" ]
    then
        echo " value can't be empty."
        return 1
    fi
    
    if [[ "$1" =~ ^[0-9]+$ ]]
    then
        if [ "$2" == "integer" ]
        then
            return 0
        else
            echo "The value should be a String."
            return 1
        fi
    fi
    
    if [[ "$1" =~ ^[a-zA-Z0-9_]+$ ]];
    then
        if [ "$2" == "string" ]
        then
            return 0
        else
            echo "The value should be an Integer."
            return 1
        fi
    fi
    
}


#----------------------- End Utils Fuctions-----------------------------------------

#----------------------- Start Fuctions Area-----------------------------------------

function createDb {
    
    typeset status DbName
    
    while true
    do
        read -p "Enter the Database name: " DbName
        validateParamName $DbName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ -d "databases/$DbName" ]
    then
        echo "A Database with same name already exist"
    else
        mkdir databases/$DbName
        echo "Database Created Successfully"
    fi
    
}

function listDbs {
    if [ -n "$(ls databases/)" ]
    then
        echo "Databases List : "
        ls databases/
    else
        echo "No Databases Found"
    fi
}

function connectDb {
    
    typeset DbName
    
    if [ -z "$(ls databases/ )" ]
    then
        echo "No Databases Found To connect"
        return
    fi
    
    while true
    do
        read -p "Enter Database name: " DbName
        validateParamName $DbName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ ! -d "databases/$DbName" ]
    then
        echo "Database Not Found"
    else
        cd databases/$DbName
        echo "You are connected to $DbName database"
        showTablesMenu
    fi
    
}

function DropDb {
    
    typeset DbName
    
    if [ -z "$(ls databases/ )" ]
    then
        echo "No Databases Found To Remove"
        return
    fi
    
    while true
    do
        read -p "Enter Database Name: " DbName
        validateParamName $DbName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ ! -d "databases/$DbName" ]
    then
        echo "Database Not Found"
    else
        rm -r databases/$DbName
        echo "$DbName deleted successfully"
    fi
    
}

function createTable {
    
    typeset tableName cols num=0 nameRecord="" dataTypeRecord=""
    
    while true
    do
        read -p "Enter Table Name: " tableName
        validateParamName $tableName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ -d "$tableName" ]
    then
        echo "Table Already Exists"
        return
    fi
    
    mkdir $tableName
    cd $tableName
    
    touch "${tableName}.txt"
    touch "${tableName}-meta.txt"
    
    while true
    do
        read -p "Enter Number Of Columns: " cols
        if [[ ! $cols =~ ^[0-9]+$ ]]
        then
            echo "Cols number must be a number"
            exit
        elif [ $cols -eq 0 ]
        then
            echo "Cols number should be greater than 0"
            exit
        fi
        break
    done
    
    typeset colName colType
    while [ $num -lt $cols ]
    do
        if [ $num -eq 0 ]
        then
            read -p "Enter The PK Column: " colName
        else
            read -p "Enter Column Name: " colName
        fi
        
        echo "Choose an option: "
        select colType in "string" "integer"
        do
            case $colType in
                "integer" | "string" ) break ;;
                *) echo "Invalid Choice" ;;
            esac
        done
        
        if [ $num -eq $((cols-1)) ]
        then
            nameRecord="${nameRecord}${colName}"
            dataTypeRecord="${dataTypeRecord}${colType}"
        else
            nameRecord="${nameRecord}${colName}:"
            dataTypeRecord="${dataTypeRecord}${colType}:"
        fi
        let num=$num+1
    done
    
    echo $dataTypeRecord >> "${tableName}-meta.txt"
    echo $nameRecord >> "${tableName}-meta.txt"
    
    cd ../
    
}

function listTables {
    if [ -z "$(ls)" ]
    then
        echo "No Tables To Show, Database Is Empty."
    else
        ls
    fi
}

function dropTable {
    typeset tableName
    
    if [ -z "$(ls)" ]
    then
        echo "No Tables To Drop, Database Is Empty."
    else
        while true
        do
            read -p "Enter Table Name: " tableName
            validateParamName $tableName
            if [ $? -eq 0 ]
            then
                break
            fi
        done
        
        if [ -d "$tableName" ]
        then
            rm -r "$tableName"
            echo "Table ${tableName} deleted successfully"
        else
            echo "Table ${tableName} Doesn't Exist"
            return
        fi
    fi
}

function insertTable {
    
    if [ -z "$(ls)" ]
    then
        echo "No Tables To Insert, Database Is Empty."
        return
    fi
    
    typeset tableName
    while true
    do
        read -p "Enter Table Name: " tableName
        validateParamName $tableName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ ! -d "$tableName" ]
    then
        echo "Table Doesn't Exist"
        return
    fi
    
    typeset colNum
    colNum=$( head -1 ${tableName}/${tableName}-meta.txt | awk -F':' '{print NF}')
    
    typeset num=0
    typeset insertVal=""
    while [ $num -lt $colNum ]
    do
        typeset colName=$(tail -1 ${tableName}/${tableName}-meta.txt | cut -d ':' -f $((num+1)))
        typeset colDatatype=$(head -1 ${tableName}/${tableName}-meta.txt | cut -d ':' -f $((num+1)))
        
        while true
        do
            read -p "Enter value of ${colName} in ${colDatatype}: " colValue
            validateDataType $colValue $colDatatype
            
            if [ $num -eq 0 ]
            then
                if [ ! -z "$(grep ^${colValue} ${tableName}/${tableName}.txt)" ]
                then
                    echo "This Pk Exist, choose another one"
                    continue
                fi
            fi
            
            if [ $? -eq 0 ]
            then
                break
            fi
        done
        
        if [ $num -eq $((colNum-1)) ]
        then
            insertVal="${insertVal}${colValue}"
        else
            insertVal="${insertVal}${colValue}:"
        fi
        
        let num=$num+1
    done
    
    echo ${insertVal} >> "${tableName}/${tableName}.txt"
    
}

function deleteRecord {
    
    typeset pk tableName
    
    if [ -z "$(ls)" ]
    then
        echo "No Tables To Remove, Database Is Empty."
        return
    fi
    
    while true
    do
        read -p "Enter Table Name: " tableName
        validateParamName $tableName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ ! -d "$tableName" ]
    then
        echo "Table Doesn't Exist"
        return
    fi
    
    if [ -s "$tableName/$$tableName.txt" ]
    then
        echo "The $tableName is empty."
        return
    fi
    
    
    read -p "Enter the pk of the table to delete: " pk
    
    while true
    do
        if [ ! -z "$(grep ^${pk} ${tableName}/${tableName}.txt)" ]
        then
            sed -i "/^${pk}/d" "${tableName}/${tableName}.txt"
            echo "The record of Pk = ${pk} has been deleted successfully."
            break
        else
            echo "The PK doesn't Exist"
            return
        fi
    done
    
}

function selectTable {
    
    typeset tableName colsNum
    
    if [ -z "$(ls)" ]
    then
        echo "No Tables To Select From, Database Is Empty."
        return
    fi
    
    while true
    do
        read -p "Enter Table Name: " tableName
        validateParamName $tableName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ ! -d "$tableName" ]
    then
        echo "Table Doesn't Exist"
        return
    fi
    
    if [ -s "$tableName/$$tableName.txt" ]
    then
        echo "The $tableName is empty."
        return
    fi
    
    tail -1 ${tableName}/${tableName}-meta.txt | sed 's/:/\t/g'
    sed 's/:/\t/g'  ${tableName}/${tableName}.txt && echo
    
}

function updateTable {
    typeset tableName pk colName oldValue newValue colnum
    
    if [ -z "$(ls)" ]
    then
        echo "No Tables To Delete, Database Is Empty."
        return
    fi
    
    while true
    do
        read -p "Enter Table Name: " tableName
        validateParamName $tableName
        if [ $? -eq 0 ]
        then
            break
        fi
    done
    
    if [ ! -d "$tableName" ]
    then
        echo "${tableName} Doesn't Exist"
        return
    fi
    
    if [ -z "$(cat "$tableName/$tableName.txt")" ]
    then
        echo "The $tableName is empty."
        return
    fi
    
    read -p "Enter Pk: " pk
    
    if [ -z "$(grep ^${pk} ${tableName}/${tableName}.txt)" ]
    then
        echo "The PK doesn't Exist"
        return
    fi
    
    read -p "Enter column name: " colName
    
    if [ -z "$(grep ${colName} ${tableName}/${tableName}-meta.txt)" ]
    then
        echo "The ${colName} column doesn't Exist"
        return
    fi
    
    colnum=$(awk -F: '{ for (i=1; i<=NF; i++) { if ($i == "'"$colName"'") { print i; exit } } }' ${tableName}/${tableName}-meta.txt)
    oldValue=$( grep "^${pk}" ${tableName}/${tableName}.txt | cut -d ':' -f $colnum )
    
    read -p "Enter New Value: " newValue
    
    sed -i "/^$pkValue/s/$oldValue/$newValue/" ${tableName}/${tableName}.txt
}

function showTablesMenu {
    select choice2 in "Create Table" "List Tables" "Drop Tables" "Insert" "Select" "Delete" "Update" "Quit"
    do
        case $choice2 in
            "Create Table") createTable
            ;;
            "List Tables") listTables
            ;;
            "Drop Tables") dropTable
            ;;
            "Insert") insertTable
            ;;
            "Select") selectTable
            ;;
            "Delete") deleteRecord
            ;;
            "Update") updateTable
            ;;
            "Quit")
                cd ../..
                break
            ;;
            *) echo "$choice2 is not valid"
            ;;
        esac
    done
}

#----------------------- End Fuctions Area-----------------------------------------

#----------------------- Start Script Main body------------------------------------
PS3="Select Option: "

select choice in "Create Database" "List Databases" "Connect Database" "Drop Database" "Exit"
do
    case $choice in
        "Create Database") createDb
        ;;
        "List Databases") listDbs
        ;;
        "Connect Database") connectDb
        ;;
        "Drop Database") DropDb
        ;;
        "Exit") exit
        ;;
        *) echo "$choice is not valid"
        ;;
    esac
done
#----------------------- End Script Main body------------------------------------
