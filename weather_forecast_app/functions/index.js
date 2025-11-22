const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

admin.initializeApp();
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Protect the endpoint with a simple shared secret (set in environment)
const SECRET = functions.config().weather?.secret || process.env.WEATHER_NOTIFICATION_SECRET;

function verifySecret(req, res) {
    const secret = req.headers['x-weather-secret'] || req.body?.secret;
    if (!SECRET) {
        console.warn('No SECRET configured for weather notifications!');
        return res.status(500).json({ error: 'Server not configured' });
    }
    if (!secret || secret !== SECRET) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    return null;
}

app.post('/send', async (req, res) => {
    try {
        const err = verifySecret(req, res);
        if (err) return;

        const { title, body, topic, token, data } = req.body;
        if (!title || !body) return res.status(400).json({ error: 'title and body required' });

        const message = {
            notification: { title, body },
            android: { priority: 'high' },
            apns: { headers: { 'apns-priority': '10' } },
            data: data || {},
        };

        if (topic) {
            await admin.messaging().send({ ...message, topic });
            return res.status(202).json({ ok: true, method: 'topic', topic });
        }

        if (token) {
            await admin.messaging().send({ ...message, token });
            return res.status(202).json({ ok: true, method: 'token' });
        }

        return res.status(400).json({ error: 'token or topic required' });
    } catch (e) {
        console.error('Send failed', e);
        return res.status(500).json({ error: 'send failed', detail: String(e) });
    }
});

exports.app = functions.https.onRequest(app);
