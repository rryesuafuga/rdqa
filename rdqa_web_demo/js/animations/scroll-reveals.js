// ============================================
// Scroll Reveal Animations
// ============================================

export function initScrollReveals() {
  const revealElements = document.querySelectorAll('.reveal, .reveal-left, .reveal-right, .reveal-scale, .stagger-children');

  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    revealElements.forEach(el => el.classList.add('active'));
    return;
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('active');
        observer.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.15,
    rootMargin: '0px 0px -50px 0px'
  });

  revealElements.forEach(el => observer.observe(el));
}

export function initChartVisibility() {
  const charts = document.querySelectorAll('.chart-container');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        // Trigger chart render if it has a render callback
        const renderFn = entry.target.getAttribute('data-render');
        if (renderFn && window.__chartRenderers && window.__chartRenderers[renderFn]) {
          window.__chartRenderers[renderFn]();
        }
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.2 });

  charts.forEach(el => observer.observe(el));
}
