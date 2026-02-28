// ============================================================
// 認証局 (CA) の仕組み ― インタラクティブ演出
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
  initProgressBar();
  initScrollReveal();
  initChainAnimation();
  initFlowAnimation();
  initCertInspector();
  initTLSSimulator();
  initVerificationDemo();
  initTypingDiagrams();
  initTableHighlight();
  initParticles();
});

// ────────────────────────────────────────────────────────────
//  1. Reading Progress Bar
// ────────────────────────────────────────────────────────────
function initProgressBar() {
  const bar = document.getElementById('progress-bar');
  if (!bar) return;
  window.addEventListener('scroll', () => {
    const h = document.documentElement;
    const pct = (h.scrollTop / (h.scrollHeight - h.clientHeight)) * 100;
    bar.style.width = pct + '%';
  }, { passive: true });
}

// ────────────────────────────────────────────────────────────
//  2. Scroll Reveal (IntersectionObserver)
// ────────────────────────────────────────────────────────────
function initScrollReveal() {
  const els = document.querySelectorAll('.reveal');
  if (!els.length) return;
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('revealed');
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.12 });
  els.forEach(el => io.observe(el));
}

// ────────────────────────────────────────────────────────────
//  3. Certificate Chain ― click‑to‑expand + SVG particle line
// ────────────────────────────────────────────────────────────
function initChainAnimation() {
  const nodes = document.querySelectorAll('.chain-node[data-detail]');
  nodes.forEach(node => {
    node.style.cursor = 'pointer';
    node.addEventListener('click', () => {
      // toggle detail
      let detail = node.querySelector('.chain-detail');
      if (detail) {
        detail.remove();
        node.classList.remove('expanded');
        return;
      }
      // close others
      document.querySelectorAll('.chain-detail').forEach(d => {
        d.remove();
        d.closest('.chain-node')?.classList.remove('expanded');
      });
      detail = document.createElement('div');
      detail.className = 'chain-detail';
      detail.innerHTML = node.dataset.detail;
      node.appendChild(detail);
      node.classList.add('expanded');
      requestAnimationFrame(() => detail.classList.add('open'));
    });
  });

  // Animate arrows
  const arrows = document.querySelectorAll('.chain-arrow-svg');
  const io = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('animate');
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.5 });
  arrows.forEach(a => io.observe(a));
}

// ────────────────────────────────────────────────────────────
//  4. Flow Steps ― staggered entrance
// ────────────────────────────────────────────────────────────
function initFlowAnimation() {
  document.querySelectorAll('.flow').forEach(flow => {
    const steps = flow.querySelectorAll('.flow-step');
    const io = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          steps.forEach((s, i) => {
            setTimeout(() => s.classList.add('flow-visible'), i * 180);
          });
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.15 });
    io.observe(flow);
  });
}

// ────────────────────────────────────────────────────────────
//  5. Interactive Certificate Inspector
// ────────────────────────────────────────────────────────────
function initCertInspector() {
  const inspector = document.getElementById('cert-inspector');
  if (!inspector) return;

  const fields = inspector.querySelectorAll('.cert-field');
  const infoPanel = document.getElementById('cert-info-panel');

  fields.forEach(f => {
    f.addEventListener('mouseenter', () => {
      fields.forEach(x => x.classList.remove('active'));
      f.classList.add('active');
      if (infoPanel) {
        infoPanel.innerHTML = f.dataset.info;
        infoPanel.classList.add('visible');
      }
    });
  });

  inspector.addEventListener('mouseleave', () => {
    fields.forEach(x => x.classList.remove('active'));
    if (infoPanel) infoPanel.classList.remove('visible');
  });
}

// ────────────────────────────────────────────────────────────
//  6. TLS Handshake Simulator
// ────────────────────────────────────────────────────────────
function initTLSSimulator() {
  const sim = document.getElementById('tls-sim');
  if (!sim) return;

  const btn = sim.querySelector('.sim-start');
  const messages = sim.querySelectorAll('.sim-msg');
  const status = sim.querySelector('.sim-status');
  const lockIcon = sim.querySelector('.sim-lock');

  if (btn) {
    btn.addEventListener('click', () => {
      // reset
      messages.forEach(m => {
        m.classList.remove('sent', 'received');
        m.style.opacity = '0.25';
      });
      if (lockIcon) { lockIcon.classList.remove('locked'); lockIcon.textContent = '🔓'; }
      if (status) { status.textContent = '接続開始...'; status.className = 'sim-status running'; }
      btn.disabled = true;

      messages.forEach((msg, i) => {
        setTimeout(() => {
          msg.style.opacity = '1';
          msg.classList.add(msg.dataset.dir === 'right' ? 'sent' : 'received');
          if (status) status.textContent = msg.dataset.label;
        }, (i + 1) * 900);
      });

      setTimeout(() => {
        if (lockIcon) { lockIcon.classList.add('locked'); lockIcon.textContent = '🔒'; }
        if (status) { status.textContent = '✅ 安全な接続が確立されました'; status.className = 'sim-status done'; }
        btn.disabled = false;
      }, (messages.length + 1) * 900);
    });
  }
}

// ────────────────────────────────────────────────────────────
//  7. Verification Demo ― interactive checklist
// ────────────────────────────────────────────────────────────
function initVerificationDemo() {
  const demo = document.getElementById('verify-demo');
  if (!demo) return;

  const checks = demo.querySelectorAll('.verify-check');
  const result = demo.querySelector('.verify-result');
  let checked = 0;

  checks.forEach(c => {
    c.addEventListener('click', () => {
      if (c.classList.contains('checked')) return;
      c.classList.add('checked');
      const icon = c.querySelector('.check-icon');
      if (icon) icon.textContent = '✅';
      checked++;
      if (checked === checks.length && result) {
        result.classList.add('show');
      }
    });
  });

  // reset button
  const resetBtn = demo.querySelector('.verify-reset');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      checked = 0;
      checks.forEach(c => {
        c.classList.remove('checked');
        const icon = c.querySelector('.check-icon');
        if (icon) icon.textContent = '⬜';
      });
      if (result) result.classList.remove('show');
    });
  }
}

// ────────────────────────────────────────────────────────────
//  8. Typing Diagrams
// ────────────────────────────────────────────────────────────
function initTypingDiagrams() {
  document.querySelectorAll('.diagram-box[data-typing]').forEach(box => {
    const pre = box.querySelector('pre');
    if (!pre) return;
    const full = pre.textContent;
    pre.textContent = '';
    pre.style.minHeight = '80px';

    const io = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          typeText(pre, full, 8);
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.3 });
    io.observe(box);
  });
}

function typeText(el, text, speed) {
  let i = 0;
  const tick = () => {
    if (i < text.length) {
      // type several chars at once for speed
      const chunk = text.slice(i, i + 3);
      el.textContent += chunk;
      i += 3;
      setTimeout(tick, speed);
    }
  };
  tick();
}

// ────────────────────────────────────────────────────────────
//  9. Table row hover highlight
// ────────────────────────────────────────────────────────────
function initTableHighlight() {
  document.querySelectorAll('.info-table tbody tr').forEach(row => {
    row.addEventListener('mouseenter', () => row.classList.add('row-glow'));
    row.addEventListener('mouseleave', () => row.classList.remove('row-glow'));
  });
}

// ────────────────────────────────────────────────────────────
// 10. Floating Particles (header decoration)
// ────────────────────────────────────────────────────────────
function initParticles() {
  const canvas = document.getElementById('particle-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  let w, h;
  const particles = [];
  const COUNT = 40;

  function resize() {
    w = canvas.width = canvas.parentElement.offsetWidth;
    h = canvas.height = canvas.parentElement.offsetHeight;
  }
  resize();
  window.addEventListener('resize', resize);

  for (let i = 0; i < COUNT; i++) {
    particles.push({
      x: Math.random() * w,
      y: Math.random() * h,
      r: Math.random() * 2 + 0.5,
      dx: (Math.random() - 0.5) * 0.5,
      dy: (Math.random() - 0.5) * 0.5,
      alpha: Math.random() * 0.4 + 0.1,
    });
  }

  function draw() {
    ctx.clearRect(0, 0, w, h);
    particles.forEach(p => {
      p.x += p.dx;
      p.y += p.dy;
      if (p.x < 0) p.x = w;
      if (p.x > w) p.x = 0;
      if (p.y < 0) p.y = h;
      if (p.y > h) p.y = 0;

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(88,166,255,${p.alpha})`;
      ctx.fill();
    });

    // draw connections
    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const dx = particles[i].x - particles[j].x;
        const dy = particles[i].y - particles[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 100) {
          ctx.beginPath();
          ctx.moveTo(particles[i].x, particles[i].y);
          ctx.lineTo(particles[j].x, particles[j].y);
          ctx.strokeStyle = `rgba(88,166,255,${0.12 * (1 - dist / 100)})`;
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(draw);
  }
  draw();
}
