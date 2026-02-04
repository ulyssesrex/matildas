const navLinks = document.querySelectorAll('.nav-link');

navLinks.forEach((link) => {
  link.addEventListener('click', (event) => {
    const href = link.getAttribute('href');
    if (!href || !href.startsWith('#')) return;

    if (href === '#home') {
      event.preventDefault();
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }

    const target = document.querySelector(href);
    if (!target) return;

    event.preventDefault();
    target.scrollIntoView({ behavior: 'smooth' });
  });
});

const iframeIncludes = document.querySelectorAll('[data-iframe-include]');

iframeIncludes.forEach((placeholder) => {
  const path = placeholder.getAttribute('data-iframe-include');
  if (!path) return;

  fetch(path)
    .then((response) => {
      if (!response.ok) {
        throw new Error(`Failed to load iframe include: ${path}`);
      }
      return response.text();
    })
    .then((html) => {
      const template = document.createElement('template');
      template.innerHTML = html.trim();
      placeholder.replaceWith(template.content);
    })
    .catch((error) => {
      console.error(error);
      placeholder.remove();
    });
});

const showsTable = document.querySelector('table[aria-label="Shows"]');

if (showsTable) {
  const showsSectionBody = showsTable.closest('.section-body');

  fetch('show-list.csv')
    .then((response) => {
      if (!response.ok) {
        throw new Error('Failed to load show list');
      }
      return response.text();
    })
    .then((csvText) => {
      const rows = parseCsv(csvText);
      if (!rows.length) return [];

      const [headerRow, ...dataRows] = rows;
      const headers = headerRow.map((header) => header.trim());

      return dataRows.map((row) => {
        const entry = {};
        headers.forEach((header, index) => {
          entry[header] = (row[index] || '').trim();
        });
        return entry;
      });
    })
    .then((entries) => {
      if (!entries || !entries.length) {
        renderNoShowsMessage(showsSectionBody);
        return;
      }

      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const weekAgo = new Date(todayStart);
      weekAgo.setDate(weekAgo.getDate() - 7);

      const recentAndUpcomingShows = entries.filter((entry) => {
        const dateStr = entry.Date;
        if (!dateStr) return false;

        const parsedDate = new Date(`${dateStr}T00:00:00`);
        if (Number.isNaN(parsedDate.getTime())) return false;

        return parsedDate >= weekAgo;
      });

      if (!recentAndUpcomingShows.length) {
        renderNoShowsMessage(showsSectionBody);
        return;
      }

      populateShowsTable(showsTable, recentAndUpcomingShows);
    })
    .catch((error) => {
      console.error(error);
      renderNoShowsMessage(showsSectionBody);
    });
}

function parseCsv(text) {
  const rows = [];
  let currentValue = '';
  let row = [];
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];

    if (char === '"') {
      if (inQuotes && next === '"') {
        currentValue += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char === ',' && !inQuotes) {
      row.push(currentValue);
      currentValue = '';
      continue;
    }

    if ((char === '\n' || char === '\r') && !inQuotes) {
      row.push(currentValue);
      if (row.some((value) => value.trim() !== '')) {
        rows.push(row);
      }
      row = [];
      currentValue = '';
      if (char === '\r' && next === '\n') {
        i += 1;
      }
      continue;
    }

    currentValue += char;
  }

  if (currentValue || row.length) {
    row.push(currentValue);
    if (row.some((value) => value.trim() !== '')) {
      rows.push(row);
    }
  }

  return rows;
}

function populateShowsTable(table, shows) {
  const tbody = table.querySelector('tbody');
  if (!tbody) return;

  shows.forEach((show) => {
    const row = document.createElement('tr');
    ['Date', 'Time', 'Venue', 'Address', 'Price', 'Notes'].forEach((key) => {
      const cell = document.createElement('td');
      cell.textContent = show[key] || '';
      row.appendChild(cell);
    });
    tbody.appendChild(row);
  });

  table.classList.remove('visually-hidden');
}

function renderNoShowsMessage(sectionBody) {
  if (!sectionBody) return;
  const message = document.createElement('p');
  message.textContent = 'No upcoming shows -- stay tuned!';
  sectionBody.appendChild(message);
}
