#run query (from other repo for vuls v2), export csv, slap in folder and then let script run
#script is designed for CLM, thats why you need to manually export the data from defender and move it to a folder (company restrictions, too lazy to update and test in private env)


#all software:
# acrobat reader (adobe), log4j (apache), commons_text (apache), tomcat (apache), zulu (azul), chrome (google), edge_chromium-based (microsoft), 
# .net (microsoft), office (microsoft), teams (microsoft), visual studio (microsoft), windows_11 (microsoft), firefox_esr (mozilla), openssl (openssl),
# jdk (oracle), jre (oracle), python (python), 


$csvInputFolder = "C:\Users\WRZLBU\Desktop\Vuls Excel\KQL_Exports"
$today = Get-Date -Format "ddMMyyyy"

$csvmaster = "C:\Users\WRZLBU\Desktop\Vuls Excel\KQL_Exports\FactorBank_Vulnerability_Report_$today.csv"

$csvfiles = Get-ChildItem -Path $csvInputFolder -Filter *.csv

#combine all files into master csv file because constrained language mode lmao fuck me
$first = $true
foreach($file in $csvfiles){
    Write-Host "Processing $($file.Name)..."

    if($first){
        Get-Content $file.FullName | Out-File $csvmaster -Encoding utf8
        $first = $false
    } else {
        Get-Content $file.FullName | Select-Object -Skip 1 | Out-File $csvmaster -Append -Encoding utf8
    }
}


#TODO: add some sort of analysis or eval here
#load csvmaster back in for report
$data = Import-Csv $csvmaster

Write-Host "Evaluating Software Totals..."
$softwareSummary = $data | Group-Object SoftwareName | Select-Object Name, Count | Sort-Object Count -Descending

Write-Host "Evaluating Severity status..."
$severitySummary = $data | Group-Object VulnerabilitySeverityLevel | Select-Object Name, Count

Write-Host "Evaluating top 10 vuls..."
$topCVEs = $data | Group-Object CveId | Select-Object Name, Count | Sort-Object Count -Descending | Select-Object -First 10

Write-Host "Evaluating most vulnerable devices..."
$topDevices = $data | Group-Object DeviceName | Select-Object Name, Count | Sort-Object Count -Descending | Select-Object -First 25



#notes aka actual manual report or analysis of the report
$analystReason = "REASON: ALL HAIL THE OMNISSIAH, FOR THE FLESH IS WEAK BUT THE MACHINE IS ETERNAL!"
$analystRemediation = "REMEDIATION: ALL HAIL THE OMNISSIAH, FOR THE FLESH IS WEAK BUT THE MACHINE IS ETERNAL!"
$analystComment = "COMMENT: ALL HAIL THE OMNISSIAH, FOR THE FLESH IS WEAK BUT THE MACHINE IS ETERNAL!"


#export to html because CLM fml
$htmlPath = "C:\Users\WRZLBU\Desktop\Vuls Excel\KQL_Exports\FactorBank_VulReport_Dashboard_$today.html"

$css = "<style>
    body { font-family: Segoe UI, sans-serif; margin: 20px; color: #333; }
    h2 { border-bottom: 2px solid #0078D4; padding-bottom: 5px; width: 50%; }
    table { border-collapse: collapse; width: 50%; margin-bottom: 30px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #0078D4; color: white; }
    .analyst-box { 
        background-color: #f3f2f1; 
        border-left: 5px solid #0078D4; 
        padding: 15px; 
        width: calc(50% - 30px); 
        margin-bottom: 30px; 
    }
    .analyst-box h3 { margin-top: 0; color: #0078D4; }
    .analyst-box p { margin: 5px 0; }
</style>"

$assessmentHtml = "
<div class='analyst-box'>
    <h3>Security Analyst Assessment</h3>
    <p><strong>Reason for Vulnerabilities:</strong> $analystReason</p>
    <p><strong>Recommended Remediation:</strong> $analystRemediation</p>
    <p><strong>Additional Comments:</strong> $analystComment</p>
</div>"

$htmlReport = "<html><head><title>Biweekly Vulnerability Report</title>$css</head><body>"
$htmlReport += "<h2>Vulnerable Devices by Software</h2>" + ($softwareSummary | ConvertTo-Html -Fragment)
$htmlReport += $assessmentHtml
$htmlReport += "<h2>Severity Status</h2>" + ($severitySummary | ConvertTo-Html -Fragment)
$htmlReport += "<h2>Top 10 Vulnerabilities</h2>" + ($topCVEs | ConvertTo-Html -Fragment)
$htmlReport += "<h2>Top 25 Most Vulnerable Devices</h2>" + ($topDevices | ConvertTo-Html -Fragment)
$htmlReport += "</body></html>"

$htmlReport | Out-File $htmlPath -Encoding utf8
Write-Host "Dashboard generated at $htmlPath"



#delete all files except for master
foreach($file in $csvfiles) {
    if($file.FullName -ne $csvmaster -and $file.FullName -ne $htmlReport){
        Remove-Item $file.FullName -Recurse -Force
    }
}

Write-Host "Done... Check sheet $csvmaster"
