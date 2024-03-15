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
${timeoutsec}       300
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

    # Open Allscripts PM When Icon Is Visible
    SeleniumLibrary.Wait Until Element Is Visible    //*[@id="AppFeed_id1AppDisplay"]/div[3]
    SeleniumLibrary.Click Element    //*[@id="AppFeed_id1AppDisplay"]/div[3]

    # Run RDP File That Is Downloaded
    OperatingSystem.Wait Until Created    ${RPA_Path}\\cpub-AllscriptsPM-${POD}-CmsRdsh.rdp
    Process.Start Process    mstsc    ${RPA_Path}\\cpub-AllscriptsPM-${POD}-CmsRdsh.rdp

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

    #Primary Test :A1 - Wait Until Screen Contains Veradigm Practice mgmt
     TRY
        ${veradigm_practice_management}=    SikuliLibrary.Exists    vrdgm_pm_login_pg    ${timeoutsec_30}
        IF    ${veradigm_practice_management} == True
            SikuliLibrary.Click    drp_dwn_btn_pm_login
            SikuliLibrary.click    drp_dwn_btn_pm_login_test
            SikuliLibrary.click    drp_dwn_btn_pm_login_continue
        END
    EXCEPT
        BuiltIn.Log To Console    "Veradigm PM Launcher is visible  - Nothing To Do"
        BuiltIn.Log    "Veradigm PM Launcher is visible - Nothing To Do"
    END
    
    #Primary Test :A2 - Close if CMD prompt window apper
     TRY
        ${cmd_prompt_stuck}=    SikuliLibrary.Exists    cmd_prmt_wndw    ${timeoutsec_30}
        IF    ${cmd_prompt_stuck} == True
            SikuliLibrary.Click    cmd_prmt_cl_btn
        END
    EXCEPT
        BuiltIn.Log To Console    "Veradigm PM Launcher is visible  - Nothing To Do"
        BuiltIn.Log    "Veradigm PM Launcher is visible - Nothing To Do"
    END
    
    
    #Primary Test :1 - Wait Until Screen Contains The First Allscripts/Veradigm PM Screen And Search For Test Patient
    SikuliLibrary.Wait Until Screen Contain    allscripts_pm_first_screen.png    ${timeoutsec_30}
    BuiltIn.Sleep    5s
    SikuliLibrary.click    allscripts_pm_pt_reg.png    xOffset=0    yOffset=-5
    SikuliLibrary.click    allscripts_pm_open_reg.png
    SikuliLibrary.Wait Until Screen Contain    allscripts_pm_reg_tab.png    ${timeoutsec_30}

    #Primary Test : 2 wait until screen contains Scheduling > Appointment Scheduling
    SikuliLibrary.click    allscripts_pm_schd_reg.png    xOffset=0    yOffset=-5
    SikuliLibrary.click    allscripts_pm_open_ap_schd.png
    SikuliLibrary.Wait Until Screen Contain    allscripts_pm_schd_reg_tab.png    ${timeoutsec_30}
    
    #Capure whole screenshot and save 


    #${imageCoordinates}=    Get Image Coordinates    allscripts_pm_patient_field.png
    #BuiltIn.Log To Console    ${imageCoordinates}
    #SikuliLibrary.click    allscripts_pm_patient_field.png
    #SikuliLibrary.Input Text    ${EMPTY}    test
    #SikuliLibrary.click    allscripts_pm_first_search.png
    #SikuliLibrary.click    allscripts_pm_pt_ok_but.png
    #TRY
    #    ${search_ok_button_exists}=    SikuliLibrary.Exists    allscripts_pm_pt_ok_but.png
    #    IF    ${search_ok_button_exists} == True
    #        SikuliLibrary.click    allscripts_pm_pt_ok_but.png
    #    END
    #XCEPT
    #    BuiltIn.Log To Console    "No OK Button Found"
    #END
    #BuiltIn.Sleep    5s
    #${screenshot}=    Capture Region    ${imageCoordinates}
    #SikuliLibrary.Right Click    ${screenshot}    xOffset=0    yOffset=-5
    #TRY
    #    ${right_click_menu_exists}=    SikuliLibrary.Exists    allscripts_pm_rt_click_menu.png
    #    IF    ${right_click_menu_exists} == False
    #        SikuliLibrary.Right Click    ${screenshot}    xOffset=0    yOffset=-5
    #    END
    #EXCEPT
    #    BuiltIn.Log To Console    "No Right Click Menu Found"
    #END

    # Click On The Returned Patient To Get Name Of Patient To Validate Test
    #SikuliLibrary.Wait Until Screen Contain    allscripts_pm_rt_click_menu.png    ${timeoutsec}
    #SikuliLibrary.Right Click    allscripts_pm_rt_click_select_all.png
    #SikuliLibrary.click    allscripts_pm_rt_click_copy.png

    # Copy Test Patient Name To Notepad and Save It As c:\RPA\POD.txt
    #PyWindowsGuiLibrary.Launch Application    Notepad
    #PyWindowsGuiLibrary.Wait Until Window Present    title:Untitled - Notepad
    #PyWindowsGuiLibrary.Focus Application Window    title:Untitled - Notepad
    #PyWindowsGuiLibrary.Wait Until Window Element Is Visible    Edit
    #PyWindowsGuiLibrary.Set Focus To Element    Edit
    #PyWindowsGuiLibrary.Input Text    Edit    ^v
    #PyWindowsGuiLibrary.Press Keys    alt
    #PyWindowsGuiLibrary.Press Keys    f
    #PyWindowsGuiLibrary.Press Keys    s
    #PyWindowsGuiLibrary.Text Writer    ${RPA_Path}\\${POD}
    #PyWindowsGuiLibrary.Press Keys    return
    #OperatingSystem.Wait Until Created    ${RPA_Path}\\${POD}.txt
    #PyWindowsGuiLibrary.Close Application Window    Notepad

    # Close/Logout Of Allscripts PM
    SikuliLibrary.click    allscripts_pm_close_x.png    xOffset=0    yOffset=-5
    TRY
        ${red_x_exists}=    SikuliLibrary.Exists    allscripts_pm_close_x.png
        IF    ${red_x_exists} == True
            SikuliLibrary.click    allscripts_pm_close_x.png    xOffset=0    yOffset=-5
        END
    EXCEPT
        BuiltIn.Log To Console    "Red X Not Found"
    END
    SikuliLibrary.Wait Until Screen Contain    allscripts_pm_logoff.png    ${timeoutsec}
    SikuliLibrary.click    allscripts_pm_logoff_yes
    #${testresulttext}=    Get File    ${RPA_Path}\\${POD}.txt
    #builtin.Should Be Equal As Strings    ${testresulttext}    Allscripts Test_upgrade15Jan20

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
