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

  fetch('data/shows.json')
    .then((response) => {
      if (!response.ok) {
        throw new Error('Failed to load show list');
      }
      return response.json();
    })
    .then((entries) => {
      if (!Array.isArray(entries) || !entries.length) {
        renderNoShowsMessage(showsSectionBody);
        return;
      }

      const normalizedEntries = entries
        .map(normalizeShowEntry)
        .filter(Boolean);

      if (!normalizedEntries.length) {
        renderNoShowsMessage(showsSectionBody);
        return;
      }

      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const weekAgo = new Date(todayStart);
      weekAgo.setDate(weekAgo.getDate() - 7);

      const recentAndUpcomingShows = normalizedEntries.filter((entry) => {
        const dateStr = entry.date;
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

function normalizeShowEntry(entry) {
  if (!entry || !entry.date) return null;

  return {
    date: entry.date,
    time: entry.time || '',
    venue: entry.venue || '',
    location: entry.location || '',
    price: entry.price || '',
    notes: entry.notes || '',
    links: normalizeLinks(entry.links),
  };
}

function normalizeLinks(links) {
  if (!links || typeof links !== 'object') return {};

  return Object.entries(links).reduce((acc, [key, value]) => {
    if (!value) return acc;

    if (typeof value === 'string') {
      acc[key] = { url: value, text: value };
      return acc;
    }

    if (typeof value === 'object') {
      const url = value.url || value.href || '';
      if (!url) return acc;
      const text = value.text || value.label || url;
      acc[key] = { url, text };
    }

    return acc;
  }, {});
}

function renderRichText(text, links = {}) {
  if (!text) return '';
  return String(text).replace(/\{([^{}]+)\}/g, (match, key) => {
    if (!key.startsWith('links.')) return `{{${key}}}`;

    const linkKey = key.slice('links.'.length);
    const link = links[linkKey];

    if (!link || !link.url) return `{{${key}}}`;

    const safeUrl = escapeHtml(link.url);
    const safeText = escapeHtml(link.text || link.url);

    return `<a href="${safeUrl}" target="_blank" rel="noreferrer noopener">${safeText}</a>`;
  });
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => {
    switch (char) {
      case '&':
        return '&amp;';
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '"':
        return '&quot;';
      case "'":
        return '&#39;';
      default:
        return char;
    }
  });
}

function populateShowsTable(table, shows) {
  const tbody = table.querySelector('tbody');
  if (!tbody) return;

  tbody.innerHTML = '';

  shows.forEach((show) => {
    const row = document.createElement('tr');
    ['date', 'time', 'venue', 'location', 'price', 'notes'].forEach((key) => {
      const cell = document.createElement('td');
      cell.innerHTML = renderRichText(show[key], show.links);
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
