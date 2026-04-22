const express = require('express');
const cors = require('cors');
const multer = require('multer');

const app = express();
const upload = multer();

const PORT = process.env.PORT || 8787;
const KPI_BASE_URL = 'https://api.dev.kpi-drive.ru/_api/indicators';
const AUTH_TOKEN = '5c3964b8e3ee4755f2cc0febb851e2f8';

app.use(cors({ origin: true }));

function toFormData(fields) {
  const form = new FormData();
  Object.entries(fields).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      form.append(key, String(value));
    }
  });
  return form;
}

async function forwardToKpi(endpoint, fields) {
  const response = await fetch(`${KPI_BASE_URL}/${endpoint}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${AUTH_TOKEN}`,
    },
    body: toFormData(fields),
  });

  const text = await response.text();
  return {
    status: response.status,
    text,
  };
}

app.post('/api/get_mo_indicators', upload.none(), async (req, res) => {
  try {
    const forwarded = await forwardToKpi('get_mo_indicators', req.body);
    res.status(forwarded.status).type('application/json').send(forwarded.text);
  } catch (error) {
    res.status(500).json({
      STATUS: 'ERROR',
      MESSAGE: `Proxy error: ${error.message}`,
    });
  }
});

app.post('/api/save_indicator_instance_field', upload.none(), async (req, res) => {
  try {
    const forwarded = await forwardToKpi('save_indicator_instance_field', req.body);
    res.status(forwarded.status).type('application/json').send(forwarded.text);
  } catch (error) {
    res.status(500).json({
      STATUS: 'ERROR',
      MESSAGE: `Proxy error: ${error.message}`,
    });
  }
});

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.listen(PORT, () => {
  console.log(`KPI proxy started on http://localhost:${PORT}`);
});
