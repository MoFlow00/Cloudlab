const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');
const settings = {
    TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN || '',
    TELEGRAM_CHAT_ID: process.env.TELEGRAM_CHAT_ID || '',
    GITHUB_TOKEN: process.env.GITHUB_TOKEN || '',
    GITHUB_REPO: process.env.GITHUB_REPO || 'MoFlow00/base'
};

// ==================== LOG CAPTURE SYSTEM ====================
const logBuffer = [];
const browserConsoleBuffer = [];
const originalConsoleLog = console.log;

function captureLog(type, ...args) {
    const timestamp = new Date().toISOString();
    const message = args.map(a => typeof a === 'object' ? JSON.stringify(a, null, 2) : String(a)).join(' ');
    const logLine = `[${timestamp}] [${type}] ${message}`;
    logBuffer.push(logLine);
    originalConsoleLog.apply(console, args);
}

console.log = (...args) => captureLog('INFO', ...args);
console.error = (...args) => captureLog('ERROR', ...args);
console.warn = (...args) => captureLog('WARN', ...args);

// Get all captured logs as string
function getCapturedLogs() {
    let logs = logBuffer.join('\n');
    if (browserConsoleBuffer.length > 0) {
        logs += '\n\n=================== BROWSER CONSOLE LOGS ===================\n' + browserConsoleBuffer.join('\n');
    }
    return logs;
}

// Save logs to file and return file path
function saveLogsToFile(prefix = 'error_log') {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const logFilePath = path.join(__dirname, `${prefix}_${timestamp}.txt`);
    fs.writeFileSync(logFilePath, getCapturedLogs(), 'utf8');
    return logFilePath;
}

// ==================== TELEGRAM FUNCTIONS ====================
async function sendTelegramMessage(message) {
    if (settings.TELEGRAM_BOT_TOKEN && settings.TELEGRAM_CHAT_ID) {
        try {
            const url = `https://api.telegram.org/bot${settings.TELEGRAM_BOT_TOKEN}/sendMessage`;
            await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ chat_id: settings.TELEGRAM_CHAT_ID, text: message })
            });
        } catch (e) {
            originalConsoleLog("Failed to send Telegram message:", e.message);
        }
    }
}

async function sendTelegramDocument(filePath, caption = '') {
    if (settings.TELEGRAM_BOT_TOKEN && settings.TELEGRAM_CHAT_ID) {
        try {
            const fileData = fs.readFileSync(filePath);
            const formData = new FormData();
            formData.append('chat_id', settings.TELEGRAM_CHAT_ID);
            formData.append('document', new Blob([fileData]), path.basename(filePath));
            if (caption) formData.append('caption', caption);

            const url = `https://api.telegram.org/bot${settings.TELEGRAM_BOT_TOKEN}/sendDocument`;
            const response = await fetch(url, { method: 'POST', body: formData });

            if (response.ok) {
                originalConsoleLog("✅ Log file sent to Telegram successfully.");
                return true;
            } else {
                const err = await response.text();
                originalConsoleLog("❌ Failed to send log to Telegram:", err);
                return false;
            }
        } catch (e) {
            originalConsoleLog("❌ Error sending document to Telegram:", e.message);
            return false;
        }
    }
    return false;
}

async function sendTelegramPhoto(photoPath, caption = '') {
    if (settings.TELEGRAM_BOT_TOKEN && settings.TELEGRAM_CHAT_ID) {
        try {
            const fileData = fs.readFileSync(photoPath);
            const formData = new FormData();
            formData.append('chat_id', settings.TELEGRAM_CHAT_ID);
            formData.append('photo', new Blob([fileData]), path.basename(photoPath));
            if (caption) formData.append('caption', caption);

            const url = `https://api.telegram.org/bot${settings.TELEGRAM_BOT_TOKEN}/sendPhoto`;
            const response = await fetch(url, { method: 'POST', body: formData });

            if (response.ok) {
                originalConsoleLog("✅ Screenshot sent to Telegram successfully.");
                return true;
            } else {
                const err = await response.text();
                originalConsoleLog("❌ Failed to send screenshot to Telegram:", err);
                return false;
            }
        } catch (e) {
            originalConsoleLog("❌ Error sending screenshot to Telegram:", e.message);
            return false;
        }
    }
    return false;
}

// Helper function to upload file to GitHub with Retry Mechanism
async function uploadToGithub(fileName, content, retries = 3) {
    const url = `https://api.github.com/repos/${settings.GITHUB_REPO}/contents/${fileName}`;
    const headers = {
        'Authorization': `token ${settings.GITHUB_TOKEN}`,
        'Content-Type': 'application/json',
        'User-Agent': 'NodeJS-Script'
    };

    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            console.log(`[GitHub Upload] Attempt ${attempt} of ${retries}...`);
            let sha = '';
            
            // 1. Get current file SHA
            const getRes = await fetch(url, { headers });
            if (getRes.ok) {
                const data = await getRes.json();
                sha = data.sha;
            }

            const body = {
                message: `Auto update ${fileName}`,
                content: Buffer.from(content).toString('base64')
            };
            if (sha) body.sha = sha;

            // 2. Upload new content
            const putRes = await fetch(url, {
                method: 'PUT',
                headers,
                body: JSON.stringify(body)
            });

            if (putRes.ok) {
                console.log(`✅ Successfully uploaded ${fileName} to GitHub.`);
                return true;
            } else {
                const err = await putRes.json();
                console.log(`❌ GitHub API Error (Attempt ${attempt}): ${err.message}`);
            }
        } catch (error) {
            console.log(`❌ Network Error during upload (Attempt ${attempt}): ${error.message}`);
            if (error.cause) console.log(`   Cause: ${error.cause}`);
        }
        
        // Wait before retrying if not the last attempt
        if (attempt < retries) {
            console.log("⏳ Waiting 3 seconds before retrying...");
            await new Promise(r => setTimeout(r, 3000));
        }
    }
    
console.log(`❌ Failed to upload ${fileName} to GitHub after ${retries} attempts.`);
    return false;
}

(async () => {
    console.log("🚀 [Start] Script started...");
    await sendTelegramMessage("🚀 [Start] IPTV Script started...");
    
    let browser;
    let page;
    let isSuccess = false;
    let logSent = false;

    async function takeAndSendScreenshot(label) {
        if (!page) return;
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const screenshotPath = path.join(__dirname, `screenshot_${label}_${timestamp}.png`);
        try {
            await page.screenshot({ path: screenshotPath, fullPage: true });
            originalConsoleLog(`📸 Screenshot saved: ${screenshotPath}`);
            await sendTelegramPhoto(screenshotPath, `📸 Screenshot [${label}] - ${new Date().toLocaleString()}`);
        } catch (e) {
            originalConsoleLog(`⚠️ Failed to take screenshot: ${e.message}`);
        }
    }

    try {
        console.log("1. Opening browser...");
        browser = await puppeteer.launch({
            executablePath: process.env.CHROME_PATH || '/usr/bin/chromium',
            args: [
                '--no-sandbox',
                '--disable-gpu',
                '--disable-dev-shm-usage',
                '--disable-blink-features=AutomationControlled',
                '--headless=new'
            ]
        });

    console.log("✅ Browser opened successfully.");

        page = await browser.newPage();

        page.on('console', msg => {
            const text = `[Browser Console] [${msg.type().toUpperCase()}] ${msg.text()}`;
            browserConsoleBuffer.push(text);
            originalConsoleLog(text);
        });

        await page.setUserAgent('Mozilla/5.0 (Linux; Android 14; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36');

        await page.evaluateOnNewDocument(() => {
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        });

        const url = 'https://freeiptv2023-d.ottc.xyz/?action=view';
        console.log(`2. Opening URL: ${url}`);
        
        try {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 35000 });
        } catch (e) {}

        console.log("⏳ Waiting 15 seconds to bypass Cloudflare verification...");
        await new Promise(r => setTimeout(r, 15000));

        console.log("3. Waiting for 'Create Free IPTV Account' button (max 60s)...");
        const startTime = Date.now();
        const maxWait = 60000;
        let buttonFound = false;

        while (Date.now() - startTime < maxWait) {
            await new Promise(r => setTimeout(r, 1000));
            const elapsed = Math.floor((Date.now() - startTime) / 1000);

            try {
                const exists = await page.evaluate(() => {
                    const elements = Array.from(document.querySelectorAll('button, a, input[type="submit"], input[type="button"]'));
                    return elements.some(el => {
                        const textMatch = (el.innerText || el.value || '').toLowerCase().includes('create free iptv account');
                        const isVisible = el.offsetWidth > 0 && el.offsetHeight > 0;
                        const notDisabled = !el.disabled;
                        return textMatch && isVisible && notDisabled;
                    });
                });
                
                if (exists) {
                    buttonFound = true;
                    console.log(`   [${elapsed}s] ✅ Button found and ready!`);
                    await new Promise(r => setTimeout(r, 1000));
                    break;
                }
            } catch (e) {}

            if (browserConsoleBuffer.length > 0) {
                const recentLogs = browserConsoleBuffer.slice(-3);
                console.log(`   [${elapsed}s] Browser:`, recentLogs.join(' | '));
            } else {
                console.log(`   [${elapsed}s] Waiting for button...`);
            }
        }

        if (!buttonFound) {
            console.log(`   [${Math.floor((Date.now() - startTime) / 1000)}s] ⚠️ Button NOT found after max wait. Current page content:`);
            const pageText = await page.evaluate(() => document.body.innerText.substring(0, 500));
            console.log(pageText);
        }

        console.log("4. Clicking create account...");
        await page.evaluate(() => {
            const elements = Array.from(document.querySelectorAll('button, a, input[type="submit"], input[type="button"]'));
            const target = elements.find(el => {
                const textMatch = (el.innerText || el.value || '').toLowerCase().includes('create free iptv account');
                const isVisible = el.offsetWidth > 0 && el.offsetHeight > 0;
                return textMatch && isVisible && !el.disabled;
            });
            if (target) target.click();
        });

        console.log("5. Waiting for account generation details...");
        try {
            await page.waitForFunction(
                () => {
                    const text = document.body.innerText.toLowerCase();
                    return text.includes('user') || text.includes('pass') || text.includes('m3u');
                },
                { timeout: 45000 }
            );
            console.log("✅ Data appeared on page, extracting...");
            await new Promise(r => setTimeout(r, 2000)); 
        } catch (e) {
            console.log("⚠️ Timeout waiting for data. It might be a Captcha or an ad page.");
        }

        const accountData = await page.evaluate(() => {
            const data = {};

            const inputs = document.querySelectorAll('input');
            inputs.forEach(input => {
                const val = input.value || '';
                const name = (input.name || input.id || input.placeholder || '').toLowerCase();
                if (val && !['submit', 'button', 'hidden'].includes(input.type)) {
                    data[name || 'field_' + Math.random().toString(36).substring(7)] = val;
                }
            });

            const rows = document.querySelectorAll('tr');
            rows.forEach(tr => {
                const cells = tr.querySelectorAll('td, th');
                if (cells.length >= 2) {
                    const key = cells[0].innerText.trim();
                    const val = cells[1].innerText.trim() || cells[1].querySelector('input')?.value || cells[1].querySelector('a')?.href || '';
                    if (key && val) data[key] = val;
                }
            });

            const links = Array.from(document.querySelectorAll('a')).map(a => a.href);
            const m3uLink = links.find(l => l.includes('.m3u') || l.includes('get.php'));

            return {
                structured: data,
                m3uLink: m3uLink || '',
                fullText: document.body.innerText
            };
        });

        console.log("\n================ [ Extracted Account Data ] ================\n");
        
        let foundDetails = false;
        let extractedUser = '';
        let extractedPass = '';

        for (const [key, value] of Object.entries(accountData.structured)) {
            console.log(`${key} : ${value}`);
            foundDetails = true;
            
            const lowerKey = key.toLowerCase();
            if (lowerKey.includes('user')) extractedUser = value;
            if (lowerKey.includes('pass')) extractedPass = value;
        }

        // Regex Fallback Extraction
        if (!extractedUser || !extractedPass) {
            console.log("🔍 Trying fallback extraction via Regex...");
            const fullText = accountData.fullText;
            
            const userMatch = fullText.match(/(?:user(?:name)?)\s*[:=]\s*([^\s]+)/i);
            const passMatch = fullText.match(/(?:pass(?:word)?)\s*[:=]\s*([^\s]+)/i);
            
            if (userMatch && !extractedUser) extractedUser = userMatch[1];
            if (passMatch && !extractedPass) extractedPass = passMatch[1];
            
            if (extractedUser) console.log(`Regex Fallback - User: ${extractedUser}`);
            if (extractedPass) console.log(`Regex Fallback - Pass: ${extractedPass}`);
        }

        if (accountData.m3uLink) {
            console.log(`M3U Link : ${accountData.m3uLink}`);
            foundDetails = true;
        }

        if (!foundDetails && !extractedUser) {
            console.log("Full text of the area after generation:\n", accountData.fullText);
        }
        console.log("\n=================================================================\n");

        const saveContent = JSON.stringify(accountData.structured, null, 2) + 
                            (accountData.m3uLink ? `\n\nM3U Link: ${accountData.m3uLink}` : '') +
                            (extractedUser ? `\n\nExtracted User: ${extractedUser}\nExtracted Pass: ${extractedPass}` : '') +
                            `\n\nFull Text:\n${accountData.fullText}`;
        fs.writeFileSync('iptv_account.txt', saveContent);
        console.log("Account saved to: iptv_account.txt");

        if (extractedUser && extractedPass) {
            console.log("6. Reading base.m3u and replacing data...");
            if (fs.existsSync('base.m3u')) {
                let baseM3uContent = fs.readFileSync('base.m3u', 'utf8');
                
                let finalM3uContent = baseM3uContent
                    .replace(/\{USERNAME\}/g, extractedUser)
                    .replace(/\{PASSWORD\}/g, extractedPass);
                
                fs.writeFileSync('final.m3u', finalM3uContent);
                console.log("✅ final.m3u created successfully.");

                console.log("7. Uploading final.m3u to GitHub...");
                const uploadStatus = await uploadToGithub('final.m3u', finalM3uContent);
                
                if (uploadStatus) {
                    isSuccess = true;
                }
            } else {
                console.log("❌ base.m3u file not found in the current directory.");
            }
        } else {
            console.log("⚠️ Username or Password not found in the extracted data.");
        }

    } catch (err) {
        console.log(`❌ Error occurred: ${err.message}`);
        const logFilePath = saveLogsToFile();
        originalConsoleLog(`📄 Error log saved to: ${logFilePath}`);
        await sendTelegramMessage(`❌ [Error] Script failed: ${err.message}\n\nLog file has been sent.`);
        await sendTelegramDocument(logFilePath, `❌ IPTV Error Log - ${new Date().toLocaleString()}`);
        await takeAndSendScreenshot('error');
        logSent = true;
    } finally {
        if (browser) {
            await takeAndSendScreenshot('final');
            console.log("Closing browser...");
            await browser.close();
        }
        
        if (isSuccess) {
            await sendTelegramMessage("✅ [Success] Script finished successfully and final.m3u is uploaded.");
            const successLogPath = saveLogsToFile('success_log');
            await sendTelegramDocument(successLogPath, `✅ IPTV Success Log - ${new Date().toLocaleString()}`);
            console.log("🛑 [End] Script finished successfully.");
        } else if (!isSuccess && browser) {
            await sendTelegramMessage("⚠️ [Warning] Script finished, but upload or generation failed. Check terminal.");
            if (!logSent) {
                const warningLogPath = saveLogsToFile('warning_log');
                await sendTelegramDocument(warningLogPath, `⚠️ IPTV Warning Log - ${new Date().toLocaleString()}`);
            }
            console.log("🛑 [End] Script finished with warnings/errors.");
        }
    }
})();
