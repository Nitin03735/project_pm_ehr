*** Settings ***
Library             SeleniumLibrary
Library             PyWindowsGuiLibrary
Library             OperatingSystem
Library             Process
Library             SikuliLibrary
Library             String
Library             ArchiveLibrary
Library             DateTime

Test Teardown       Custom Teardown


*** Variables ***
${Username}         idcprod\\Auto.Health
${RPA_Path}         C:\\RPA
${IMAGE_DIR}        C:\\RPA\\img
${Launcher}         ${False}
${POD}              A03
${resultsfile}      C:\\RPA\\results.txt
${timeoutsec}       120
${timeoutsec_30}    40


*** Test Cases ***
Pod Health Checks
    Health Check


*** Keywords ***
Health Check
    # Wait For VM Extension To Create All Necessary Files
    OperatingSystem.Wait Until Created    ${RPA_Path}\\mi_client_id.txt
    OperatingSystem.Wait Until Created    ${RPA_Path}\\ghe_token.txt
    OperatingSystem.Wait Until Created    ${RPA_Path}\\splunk_hec_token.txt
    OperatingSystem.Wait Until Created    ${RPA_Path}\\autohealthpwd.txt
    OperatingSystem.Wait Until Created    ${RPA_Path}\\allowselfdestroy.txt
    OperatingSystem.Wait Until Created    ${RPA_Path}\\bloburl.txt

    # Determine Pod Name Via ComputerName
    ${HOSTNAME}=    Evaluate    socket.gethostname()    socket
    @{PODSPLIT}=    Split String    ${HOSTNAME}    -
    ${POD}=    BuiltIn.Set Variable    ${PODSPLIT}[0]

    # Code To Close Greenshot PopUp On First Login If Exists
    TRY
        Focus Application Window    title:Greenshot
        PyWindowsGuiLibrary.Click On Element    Ok
    EXCEPT
        BuiltIn.Log To Console    "Greenshot Window Not Visible - Nothing To Do"
        BuiltIn.Log    "Greenshot Window Not Visible - Nothing To Do"
    END

    # Get Autohealth Password To Login To AllscriptsPM With
    ${Password}=    Get File    C:\\RPA\\autohealthpwd.txt

    # Start Chrome For Testing And Browse To POD That Corresponds With This VM and Login
    ${prefs}=    BuiltIn.Create Dictionary    download.default_directory=${RPA_Path}
    SeleniumLibrary.Open Browser
    ...    https://${POD}.prosuite.allscriptscloud.com/RDWeb/Pages/en-US/login.aspx?ReturnUrl=/RDWeb/Pages/en-US/Default.aspx
    ...    chrome
    ...    options=add_experimental_option("prefs",${prefs});binary_location=r"C:\\Windows\\chrome-win64\\chrome.exe"
    SeleniumLibrary.Wait Until Element Is Visible    //*[@id="DomainUserName"]    ${timeoutsec}
    SeleniumLibrary.Input Text    //*[@id="DomainUserName"]    ${Username}
    SeleniumLibrary.Input Text    //*[@id="UserPass"]    ${Password}

    # Open Allscripts EHR When Icon Is Visible // Changes Made
    SeleniumLibrary.Wait Until Element Is Visible    //*[@id="AppFeed_id1AppDisplay"]/div[4]
    SeleniumLibrary.Click Element    //*[@id="AppFeed_id1AppDisplay"]/div[4]

    # Run RDP File That Is Downloaded // Changes Made
    OperatingSystem.Wait Until Created    ${RPA_Path}\\cpub-ClinicalModule-${POD}-CmsRdsh.rdp
    Process.Start Process    mstsc    ${RPA_Path}\\cpub-ClinicalModule-${POD}-CmsRdsh.rdp

    # Send RDP Username And Password
    PyWindowsGuiLibrary.Wait Until Window Present    title:RemoteApp
    PyWindowsGuiLibrary.Focus Application Window    title:RemoteApp
    PyWindowsGuiLibrary.Click On Element    Connect
    SikuliLibrary.Add Image Path    ${IMAGE_DIR}
    SikuliLibrary.Wait Until Screen Contain    windows_security_cred_screen_small.png    ${timeoutsec}
    ${userandpass}=    SikuliLibrary.Exists    windows_security_userandpass.png
    IF    ${userandpass} == True
        SikuliLibrary.Click    windows_security_username_field.png
        PyWindowsGuiLibrary.Text Writer    ${Username}
        PyWindowsGuiLibrary.Press Keys    tab
        PyWindowsGuiLibrary.Text Writer    ${Password}
    ELSE
        ${passonly}=    SikuliLibrary.Exists    windows_security_passonly.png
        IF    ${passonly} == True
            SikuliLibrary.Click    windows_security_password_field.png
            PyWindowsGuiLibrary.Text Writer    ${Password}
        END
    END

    # Interact With The Prosuite Launcher
    SikuliLibrary.Wait Until Screen Contain    prosuite_launcher_small_new.png    ${timeoutsec}
    SikuliLibrary.Double Click    prosuite_launcher_small_new.png
    SikuliLibrary.Double Click    prosuite_launcher_small_new.png
    PyWindowsGuiLibrary.Press Keys    backspace
    @{characters}=    Split String To Characters    ${POD}
    FOR    ${char}    IN    @{characters}
        PyWindowsGuiLibrary.Press Keys    ${char}
    END
    PyWindowsGuiLibrary.Press Keys    return
    SikuliLibrary.Click    prosuite_launcher_open_new.png

    # Deal With Maintenance Button If Present
    TRY
        ${maintenance_button_exists}=    SikuliLibrary.Exists    but_purple_maintenance_continue    ${timeoutsec_30}
        IF    ${maintenance_button_exists} == True
            SikuliLibrary.click    but_purple_maintenance_continue
            SikuliLibrary.click    but_purple_maintenance_continue
        END
    EXCEPT
        BuiltIn.Log To Console    "Maintenance Window Not Visible - Nothing To Do"
        BuiltIn.Log    "Maintenance Window Not Visible - Nothing To Do"
    END
    # Send EHR Cliical Module Login  Username And Password
    SikuliLibrary.Wait Until Screen Contain    vm_cm_lgn_pg.png    ${timeoutsec_30}
    ${userandpass}=    SikuliLibrary.Exists    vm_cm_lgn_pg.png
    IF    ${userandpass} == True
        SikuliLibrary.Click    vm_cm_lgn_usr.png
        PyWindowsGuiLibrary.Text Writer    ${Username}
        PyWindowsGuiLibrary.Press Keys    tab
        PyWindowsGuiLibrary.Text Writer    ${Password}
    ELSE
        ${passonly}=    SikuliLibrary.Exists    vm_cm_lgn_pwd.png
        IF    ${passonly} == True
            SikuliLibrary.Click    vm_cm_lgn_pwd.png
            PyWindowsGuiLibrary.Text Writer    ${Password}
            SikuliLibrary.click    vm_cm_lgn_btn
        END
    END
    #Primary Test :A1 - Wait Until Screen Contains Veradigm Practice mgmt
     TRY
        ${veradigm_practice_management}=    SikuliLibrary.Exists    vrdgm_pm_login_pg    ${timeoutsec_30}
        IF    ${veradigm_practice_management} == True
        SikuliLibrary.click    vm_cm_lgn_btn
        END
    EXCEPT
        BuiltIn.Log To Console    "Veradigm EHR Launcher is visible  - Nothing To Do"
        BuiltIn.Log    "Veradigm EHR Launcher is visible - Nothing To Do"
    END
    
    #Primary Test :A2 - Close if CMD prompt window apper
     TRY
        ${cmd_prompt_stuck}=    SikuliLibrary.Exists    cmd_prmt_wndw    ${timeoutsec_30}
        IF    ${cmd_prompt_stuck} == True
            SikuliLibrary.Click    cmd_prmt_cl_btn
        END
    EXCEPT
        BuiltIn.Log To Console    "Veradigm EHR Launcher is visible  - Nothing To Do"
        BuiltIn.Log    "Veradigm EHR Launcher is visible - Nothing To Do"
    END
    
    
    #Primary Test :1 - Wait Until Screen Contains The First Veradigm Clinical Module/EHR Screen and Search for Office Admin
    SikuliLibrary.Wait Until Screen Contain    vm_ehr_login_pg.png    ${timeoutsec_30}
    BuiltIn.Sleep    5s
    SikuliLibrary.click    vm_ehr_mdl_work_log1.png    xOffset=0    yOffset=-5
    SikuliLibrary.click    vm_ehr_mdl_work_log1_arrow.png
    SikuliLibrary.Wait Until Screen Contain    vm_ehr_mdl_work_log1_arrow.png    ${timeoutsec_30}
    SikuliLibrary.click    vm_cm_menu_btn.png
    SikuliLibrary.click    vm_cm_menu_about_btn.png
    SikuliLibrary.Wait Until Screen Contain    vm_cm_menu_about_pg.png    ${timeoutsec_30}
    SikuliLibrary.click    vm_cm_menu_about_ok_btn.png

    # Close/Logout Of CM EHR PM
    SikuliLibrary.click    vm_close_wnd.png    xOffset=0    yOffset=-5
    TRY
        ${red_x_exists}=    SikuliLibrary.Exists    vm_close_wnd.png
        IF    ${red_x_exists} == True
            SikuliLibrary.click    vm_close_wnd.png    xOffset=0    yOffset=-5
        END
    EXCEPT
        BuiltIn.Log To Console    "Red X Not Found"
    END
    SikuliLibrary.Wait Until Screen Contain    vm_ehr_mdl_lg_out_window.png    ${timeoutsec_30}
    SikuliLibrary.click    vm_ehr_mdl_lg_out_yes.png
    SikuliLibrary.Wait Until Screen Contain    cm_stopped_working_close.png    ${timeoutsec_30}
    SikuliLibrary.click    cm_stopped_working_close_btn.png


Custom Teardown
    # Stop Java Sikuli Server
    Stop Remote Server
    Run Keyword If Test Failed    Failed_Test_Teardown
    Run Keyword If Test Passed    Passed_Test_Teardown

Failed_Test_Teardown
    # Run Powershell Script To Send Results To SPLUNK, Upload Failed Files And Kick Off Pipeline To Destroy VM
    Process.Start Process    powershell    ${RPA_Path}\\sendtestresults.ps1    FAIL ${POD}    shell=True

Passed_Test_Teardown
    # Run Powershell Script To Send Results To SPLUNK, Upload Failed Files And Kick Off Pipeline To Destroy VM
    Process.Start Process    powershell    ${RPA_Path}\\sendtestresults.ps1    PASS ${POD}    shell=True
