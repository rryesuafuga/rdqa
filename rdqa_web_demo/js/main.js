// ============================================
// RDQA Demo — Main Application
// ============================================
import { initHeroParticles } from './animations/hero.js';
import { animateCounters } from './animations/counters.js';
import { initScrollReveals, initChartVisibility } from './animations/scroll-reveals.js';
import { renderVerificationFactorChart } from './charts/verification-factor.js';
import { renderSpiderChart } from './charts/spider-chart.js';
import { renderRootCauseChart } from './charts/root-cause.js';
import { renderTimeline } from './charts/timeline.js';
import { renderDistrictCompare } from './charts/district-compare.js';
import { renderTriangulation } from './charts/sankey.js';
import { facilities, indicators, rootCauses, getDistrictStats } from './data.js';

// ---- Navigation ---- //
function initNav() {
  const nav = document.querySelector('.nav');
  const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');

  // Scroll state
  window.addEventListener('scroll', () => {
    nav.classList.toggle('scrolled', window.scrollY > 50);
  }, { passive: true });

  // Smooth scroll
  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const target = document.querySelector(link.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // Active section tracking
  const sections = document.querySelectorAll('section[id]');
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        navLinks.forEach(l => l.classList.remove('active'));
        const active = document.querySelector(`.nav-links a[href="#${entry.target.id}"]`);
        if (active) active.classList.add('active');
      }
    });
  }, { threshold: 0.3 });

  sections.forEach(s => observer.observe(s));

  // Mobile menu
  const menuBtn = document.querySelector('.mobile-menu-btn');
  const navLinksContainer = document.querySelector('.nav-links');
  if (menuBtn) {
    menuBtn.addEventListener('click', () => {
      navLinksContainer.style.display =
        navLinksContainer.style.display === 'flex' ? 'none' : 'flex';
      navLinksContainer.style.flexDirection = 'column';
      navLinksContainer.style.position = 'absolute';
      navLinksContainer.style.top = '64px';
      navLinksContainer.style.left = '0';
      navLinksContainer.style.right = '0';
      navLinksContainer.style.background = '#fff';
      navLinksContainer.style.padding = '1rem';
      navLinksContainer.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
    });
  }
}

// ---- VF Chart Controls ---- //
function initVFControls() {
  const buttons = document.querySelectorAll('#vf-controls .chart-btn');
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      buttons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      renderVerificationFactorChart('vf-chart', btn.getAttribute('data-indicator'));
    });
  });
}

// ---- Spider Chart Controls ---- //
function initSpiderControls() {
  const buttons = document.querySelectorAll('#spider-controls .chart-btn');
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      buttons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      renderSpiderChart('spider-chart', btn.getAttribute('data-facility'));
    });
  });
}

// ---- Root Cause Details ---- //
function renderRootCauseDetails() {
  const container = document.getElementById('root-cause-details');
  if (!container) return;

  container.innerHTML = rootCauses.map(rc => `
    <div class="root-cause-item">
      <div class="root-cause-bar">
        <div class="root-cause-bar-label">
          <span>${rc.category}</span>
          <span style="color:${rc.color};font-weight:700">${rc.percentage}%</span>
        </div>
        <div class="root-cause-bar-track">
          <div class="root-cause-bar-fill" style="width:0%;background:${rc.color}" data-width="${rc.percentage}%"></div>
        </div>
        <div style="margin-top:6px;font-size:12px;color:var(--text-tertiary)">
          ${rc.examples[0]}
        </div>
      </div>
    </div>
  `).join('');

  // Animate bars on visibility
  setTimeout(() => {
    container.querySelectorAll('.root-cause-bar-fill').forEach(bar => {
      bar.style.width = bar.getAttribute('data-width');
    });
  }, 300);
}

// ---- District Stats ---- //
function renderDistrictStats() {
  const kampala = getDistrictStats('District A (Urban)');
  const wakiso = getDistrictStats('District B (Peri-Urban)');

  const kampalaEl = document.getElementById('kampala-stats');
  const wakisoEl = document.getElementById('wakiso-stats');

  if (kampalaEl) {
    kampalaEl.querySelector('.big-number').textContent = kampala.avg + '%';
    kampalaEl.querySelector('.sub-text').textContent =
      `${kampala.pctWithin}% within tolerance (${kampala.withinTolerance}/${kampala.total} VFs)`;
  }
  if (wakisoEl) {
    wakisoEl.querySelector('.big-number').textContent = wakiso.avg + '%';
    wakisoEl.querySelector('.sub-text').textContent =
      `${wakiso.pctWithin}% within tolerance (${wakiso.withinTolerance}/${wakiso.total} VFs)`;
  }
}

// ---- Chart Render Registry ---- //
window.__chartRenderers = {
  'vf-chart': () => renderVerificationFactorChart('vf-chart', 'fp'),
  'spider-chart': () => renderSpiderChart('spider-chart', 'UA-001'),
  'root-cause-chart': () => {
    renderRootCauseChart('root-cause-chart');
    renderRootCauseDetails();
  },
  'timeline-chart': () => renderTimeline('timeline-chart'),
  'district-chart': () => {
    renderDistrictCompare('district-chart');
    renderDistrictStats();
  },
  'triangulation-chart': () => renderTriangulation('triangulation-chart'),
};

// ---- Resize Handler ---- //
let resizeTimeout;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimeout);
  resizeTimeout = setTimeout(() => {
    // Re-render visible charts
    document.querySelectorAll('.chart-container.visible').forEach(el => {
      const renderFn = el.getAttribute('data-render');
      if (renderFn && window.__chartRenderers[renderFn]) {
        window.__chartRenderers[renderFn]();
      }
    });
  }, 300);
});

// ---- Initialize ---- //
document.addEventListener('DOMContentLoaded', () => {
  initNav();
  initHeroParticles('hero-canvas');
  animateCounters();
  initScrollReveals();
  initChartVisibility();
  initVFControls();
  initSpiderControls();
});
