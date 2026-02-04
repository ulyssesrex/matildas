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
