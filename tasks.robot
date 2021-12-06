# +
*** Settings ***
Documentation   OPEN THE WEBSITE.TAKE CSV LINK FROM THE USER.
...             ORDER USING DATA FROM THE CSV FILE. 
...             SCREENSHOT AND MAKE A PDF. SAVE IN SPECIFIC FOLDER.
...             ZIP AND TEARDOWN.
Library         RPA.Browser
Library         RPA.core.notebook
Library         RPA.Tables
Library         RPA.Robocloud.Secrets
Library         RPA.Archive
Library         RPA.FileSystem
Library         RPA.PDF
Library         RPA.HTTP
Library         Dialogs


# -


***Keywords***
NAVIGATING TO THE WESBITE
    ${web_url}=  Get Secret  websitedata
    Open Available Browser  ${web_url}[url]

***Keywords***
STEP 1   
    Remove File  ${CURDIR}${/}orders.csv
    ${reciept_folder}=  Does Directory Exist  ${CURDIR}${/}RECEIPTS OF ROBOTS
    ${robots_folder}=  Does Directory Exist  ${CURDIR}${/}RAW ROBOTS SCREENSHOTS


***Keywords***
READ THE DATA FROM CSV FILE
    ${csv_content}=  Read Table From Csv  ${CURDIR}${/}orders.csv  header=True
    Return From Keyword  ${csv_content}

***Keywords***
GETTING DATA FROM CSV AND PROCESSING
    [Arguments]  ${csv_row}
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    Select From List By Value  //select[@name="head"]  ${csv_row}[Head]
    Click Element  //input[@value="${csv_row}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${csv_row}[Legs]
    Input Text  //input[@placeholder="Shipping address"]  ${csv_row}[Address] 
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  2 seconds
    Click Button  //button[@id="order"]
    Sleep  2 seconds


***Keywords***
Stop And Start Browser Again
    Close Browser
    NAVIGATING TO THE WESBITE
    Continue For Loop

*** Keywords ***
RECEIPT CHECK 
    FOR  ${i}  IN RANGE  ${50}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Stop And Start Browser Again 

***Keywords***
FINAL PROCESSING
    [Arguments]  ${csv_row} 
    Sleep  2 seconds
    ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
    Html To Pdf  ${reciept_data}  ${CURDIR}${/}RECEIPTS OF ROBOTS${/}${csv_row}[Order number].pdf
    Screenshot  //div[@id="robot-preview-image"]  ${CURDIR}${/}RAW ROBOTS SCREENSHOTS${/}${csv_row}[Order number].png 
    #Add Watermark Image To Pdf  ${CURDIR}${/}RAW ROBOTS SCREENSHOTS${/}${csv_row}[Order number].png  ${CURDIR}${/}RECEIPTS OF ROBOTS${/}${csv_row}[Order number].pdf  ${CURDIR}${/}RECEIPTS OF ROBOTS${/}${csv_row}[Order number].pdf 
    Click Button  //button[@id="order-another"]

***Keywords***
ORDER PROCESSING
    [Arguments]  ${csv_content}
    FOR  ${csv_row}  IN  @{csv_content}    
        GETTING DATA FROM CSV AND PROCESSING  ${csv_row}
        RECEIPT CHECK
        FINAL PROCESSING  ${csv_row}      
    END  

# +
***Keywords***
DOWNLOADING DATA FILE
    ${file_url}=  Get Value From User  PLEASE ENTER THE DATA FILE URL  https://robotsparebinindustries.com/orders.csv  
    Download  ${file_url}  orders.csv
    Sleep  2 seconds
    
    
# -

***Keywords***
ZIPPING
    Archive Folder With Zip  ${CURDIR}${/}RECEIPTS OF ROBOTS  ${OUTPUT_DIR}${/}reciepts.zip


*** Tasks ***
Order Processing Bot 
    STEP 1
    DOWNLOADING DATA FILE
    ${csv_content}=  READ THE DATA FROM CSV FILE
    NAVIGATING TO THE WESBITE
    ORDER PROCESSING  ${csv_content}
    ZIPPING
    [Teardown]  Close Browser



