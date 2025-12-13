"""Enterprise Disaster Recovery Monitoring System

Azure Function for monitoring AWS infrastructure health and triggering
automated disaster recovery notifications to technical operations team.
"""

import azure.functions as func
import logging
import requests
import smtplib
import random
import json
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import os
from datetime import datetime, timezone
from typing import List, Optional
from dataclasses import dataclass
from enum import Enum

app = func.FunctionApp()

class AlertSeverity(Enum):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"

@dataclass
class MonitoringConfig:
    endpoint_url: str = "http://20.185.185.20:3000/explore/repos"
    timeout_seconds: int = 30
    retry_attempts: int = 3
    technician_emails: List[str] = None
    
    def __post_init__(self):
        if self.technician_emails is None:
            self.technician_emails = [
                "sre.lead@company.com",
                "devops.manager@company.com",
                "infrastructure.engineer@company.com",
                "platform.architect@company.com"
            ]

@dataclass
class EmailConfig:
    smtp_server: str = os.environ.get("SMTP_SERVER", "smtp.office365.com")
    smtp_port: int = int(os.environ.get("SMTP_PORT", "587"))
    sender_email: str = os.environ.get("EMAIL_USER")
    sender_password: str = os.environ.get("EMAIL_PASSWORD")
    company_name: str = os.environ.get("COMPANY_NAME", "Enterprise Solutions Inc.")
    
@dataclass
class HealthCheckResult:
    is_healthy: bool
    error_message: Optional[str]
    status_code: Optional[int]
    attempts_made: int

config = MonitoringConfig()
email_config = EmailConfig()

@app.timer_trigger(schedule="0 */5 * * * *", arg_name="myTimer", run_on_startup=False)
def disaster_recovery_monitor(myTimer: func.TimerRequest) -> None:
    """Enterprise-grade disaster recovery monitoring function.
    
    Monitors critical AWS infrastructure endpoints and triggers automated
    failover notifications when service degradation is detected.
    """
    correlation_id = f"DR-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}"
    
    logging.info(f"[{correlation_id}] Disaster Recovery Monitor - Initiating health check")
    
    health_status = perform_health_check(correlation_id)
    
    if not health_status.is_healthy:
        logging.warning(f"[{correlation_id}] Service degradation detected: {health_status.error_message}")
        send_enterprise_alert(health_status, correlation_id)
    else:
        logging.info(f"[{correlation_id}] Infrastructure health check completed successfully")

def perform_health_check(correlation_id: str) -> HealthCheckResult:
    """Perform comprehensive health check with retry logic."""
    
    for attempt in range(1, config.retry_attempts + 1):
        try:
            logging.info(f"[{correlation_id}] Health check attempt {attempt}/{config.retry_attempts}")
            
            response = requests.get(
                config.endpoint_url,
                timeout=config.timeout_seconds,
                headers={
                    'User-Agent': 'Enterprise-DR-Monitor/1.0',
                    'X-Correlation-ID': correlation_id
                }
            )
            
            if response.status_code == 200:
                return HealthCheckResult(True, None, response.status_code, attempt)
            else:
                error_msg = f"HTTP {response.status_code}: Service returned non-success status"
                if attempt == config.retry_attempts:
                    return HealthCheckResult(False, error_msg, response.status_code, attempt)
                    
        except requests.exceptions.Timeout:
            error_msg = f"Service timeout after {config.timeout_seconds}s"
        except requests.exceptions.ConnectionError:
            error_msg = "Service connection failed - potential infrastructure failure"
        except requests.exceptions.RequestException as e:
            error_msg = f"Service request failed: {str(e)}"
        except Exception as e:
            error_msg = f"Unexpected monitoring error: {str(e)}"
            
        if attempt == config.retry_attempts:
            return HealthCheckResult(False, error_msg, None, attempt)
            
        logging.warning(f"[{correlation_id}] Attempt {attempt} failed: {error_msg}")
    
    return HealthCheckResult(False, "All retry attempts exhausted", None, config.retry_attempts)

def send_enterprise_alert(health_status: HealthCheckResult, correlation_id: str) -> None:
    """Send professional disaster recovery alert to operations team."""
    
    try:
        # Select random subset of technicians for load distribution
        selected_technicians = random.sample(config.technician_emails, 
                                           min(4, len(config.technician_emails)))
        
        alert_data = generate_alert_content(health_status, correlation_id)
        
        with smtplib.SMTP(email_config.smtp_server, email_config.smtp_port) as server:
            server.starttls()
            server.login(email_config.sender_email, email_config.sender_password)
            
            for recipient in selected_technicians:
                message = create_professional_email(alert_data, recipient)
                server.send_message(message)
                
        logging.info(f"[{correlation_id}] Enterprise alert dispatched to: {', '.join(selected_technicians)}")
        
    except Exception as e:
        logging.error(f"[{correlation_id}] Critical: Failed to dispatch alert - {str(e)}")

def generate_alert_content(health_status: HealthCheckResult, correlation_id: str) -> dict:
    """Generate structured alert content for professional presentation."""
    
    current_time = datetime.now(timezone.utc)
    severity = determine_alert_severity(health_status)
    
    return {
        'correlation_id': correlation_id,
        'timestamp': current_time.strftime('%Y-%m-%d %H:%M:%S UTC'),
        'severity': severity.value,
        'service_name': 'AWS Infrastructure Monitoring',
        'endpoint': config.endpoint_url,
        'error_details': health_status.error_message,
        'status_code': health_status.status_code,
        'attempts_made': health_status.attempts_made,
        'company_name': email_config.company_name
    }

def determine_alert_severity(health_status: HealthCheckResult) -> AlertSeverity:
    """Determine alert severity based on failure characteristics."""
    if health_status.attempts_made >= config.retry_attempts:
        return AlertSeverity.CRITICAL
    elif health_status.status_code and health_status.status_code >= 500:
        return AlertSeverity.HIGH
    else:
        return AlertSeverity.MEDIUM

def create_professional_email(alert_data: dict, recipient: str) -> MIMEMultipart:
    """Create professionally formatted email with HTML content."""
    
    message = MIMEMultipart('alternative')
    message['From'] = f"{alert_data['company_name']} Operations <{email_config.sender_email}>"
    message['To'] = recipient
    message['Subject'] = f"🚨 [{alert_data['severity']}] Infrastructure Alert - Disaster Recovery Required"
    message['X-Priority'] = '1'
    message['X-MSMail-Priority'] = 'High'
    
    # Plain text version
    text_content = f"""
INFRASTRUCTURE DISASTER RECOVERY ALERT

Severity: {alert_data['severity']}
Correlation ID: {alert_data['correlation_id']}
Timestamp: {alert_data['timestamp']}

SERVICE DETAILS:
Service: {alert_data['service_name']}
Endpoint: {alert_data['endpoint']}
Error: {alert_data['error_details']}
HTTP Status: {alert_data['status_code'] or 'N/A'}
Retry Attempts: {alert_data['attempts_made']}

IMMEDIATE ACTIONS REQUIRED:
1. Verify AWS service health dashboard
2. Initiate Azure disaster recovery pipeline
3. Notify stakeholders of potential service impact
4. Confirm backup systems are operational
5. Update incident management system

This is an automated alert from the Enterprise Disaster Recovery System.
For immediate assistance, contact the Operations Center.

{alert_data['company_name']} - Infrastructure Operations Team
    """
    
    # HTML version for professional presentation
    html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #dc3545, #c82333); color: white; padding: 20px; border-radius: 8px 8px 0 0; }}
        .severity-critical {{ border-left: 5px solid #dc3545; }}
        .content {{ padding: 30px; }}
        .alert-box {{ background-color: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px; padding: 15px; margin: 20px 0; }}
        .details-table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        .details-table th, .details-table td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
        .details-table th {{ background-color: #f8f9fa; font-weight: 600; }}
        .action-list {{ background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; padding: 20px; margin: 20px 0; }}
        .action-list ol {{ margin: 0; padding-left: 20px; }}
        .action-list li {{ margin: 8px 0; font-weight: 500; }}
        .footer {{ background-color: #f8f9fa; padding: 20px; border-radius: 0 0 8px 8px; text-align: center; color: #6c757d; }}
        .correlation-id {{ font-family: 'Courier New', monospace; background-color: #e9ecef; padding: 4px 8px; border-radius: 4px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header severity-critical">
            <h1>🚨 INFRASTRUCTURE DISASTER RECOVERY ALERT</h1>
            <p style="margin: 0; font-size: 18px;">Immediate Action Required - Service Degradation Detected</p>
        </div>
        
        <div class="content">
            <div class="alert-box">
                <strong>Severity Level:</strong> <span style="color: #dc3545; font-weight: bold;">{alert_data['severity']}</span><br>
                <strong>Correlation ID:</strong> <span class="correlation-id">{alert_data['correlation_id']}</span><br>
                <strong>Detection Time:</strong> {alert_data['timestamp']}
            </div>
            
            <h3>Service Impact Details</h3>
            <table class="details-table">
                <tr><th>Service Name</th><td>{alert_data['service_name']}</td></tr>
                <tr><th>Monitored Endpoint</th><td><code>{alert_data['endpoint']}</code></td></tr>
                <tr><th>Error Description</th><td>{alert_data['error_details']}</td></tr>
                <tr><th>HTTP Status Code</th><td>{alert_data['status_code'] or 'Connection Failed'}</td></tr>
                <tr><th>Retry Attempts</th><td>{alert_data['attempts_made']} of {config.retry_attempts}</td></tr>
            </table>
            
            <div class="action-list">
                <h3>🎯 Immediate Response Protocol</h3>
                <ol>
                    <li><strong>Verify AWS Health:</strong> Check AWS Service Health Dashboard for regional issues</li>
                    <li><strong>Initiate Failover:</strong> Execute Azure disaster recovery pipeline immediately</li>
                    <li><strong>Stakeholder Notification:</strong> Alert business stakeholders of potential service impact</li>
                    <li><strong>System Validation:</strong> Confirm all backup systems are operational and accessible</li>
                    <li><strong>Incident Management:</strong> Create high-priority incident in ServiceNow/JIRA</li>
                </ol>
            </div>
            
            <p><strong>Note:</strong> This alert was automatically generated by the Enterprise Disaster Recovery Monitoring System. 
            The system will continue monitoring and will send updates as the situation evolves.</p>
        </div>
        
        <div class="footer">
            <p><strong>{alert_data['company_name']}</strong><br>
            Infrastructure Operations & Site Reliability Engineering<br>
            <em>Automated Disaster Recovery System v2.0</em></p>
        </div>
    </div>
</body>
</html>
    """
    
    # Attach both versions
    message.attach(MIMEText(text_content, 'plain'))
    message.attach(MIMEText(html_content, 'html'))
    
    return message