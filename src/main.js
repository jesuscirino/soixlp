// Navbar scroll effect
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  if (window.scrollY > 50) {
    navbar.classList.add('scrolled');
  } else {
    navbar.classList.remove('scrolled');
  }
});

// Mobile menu toggle
const menuToggle = document.getElementById('menu-toggle');
const navMenu = document.getElementById('nav-menu');

if (menuToggle) {
  menuToggle.addEventListener('click', () => {
    navMenu.classList.toggle('active');
    // Animate burger to X could be added here
  });
}

// Reveal on scroll using Intersection Observer
const observerOptions = {
  threshold: 0.1,
  rootMargin: '0px 0px -50px 0px'
};

const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('reveal-visible');
      // If it's a number counter
      if (entry.target.classList.contains('stat-number') && !entry.target.dataset.animated) {
        animateNumber(entry.target);
      }
    }
  });
}, observerOptions);

// Add reveal classes to elements
document.querySelectorAll('[data-aos]').forEach(el => {
  el.classList.add('reveal');
  revealObserver.observe(el);
});

// Simple number counter animation
function animateNumber(el) {
  const target = parseInt(el.innerText);
  if (isNaN(target)) return;
  
  let current = 0;
  const duration = 2000;
  const stepTime = Math.abs(Math.floor(duration / target));
  
  const timer = setInterval(() => {
    current += 1;
    el.innerText = current + (el.innerText.includes('%') ? '%' : el.innerText.includes('+') ? '+' : '');
    if (current >= target) {
      clearInterval(timer);
      el.dataset.animated = "true";
    }
  }, stepTime);
}

// Stats observer
document.querySelectorAll('.stat-number').forEach(stat => {
  revealObserver.observe(stat);
});

// Smooth scroll for nav links (handled by CSS, but good for custom offsets)
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      e.preventDefault();
      const offset = 80;
      const bodyRect = document.body.getBoundingClientRect().top;
      const elementRect = target.getBoundingClientRect().top;
      const elementPosition = elementRect - bodyRect;
      const offsetPosition = elementPosition - offset;

      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth'
      });
      
      // Close mobile menu if open
      if (navMenu.classList.contains('active')) {
        navMenu.classList.remove('active');
      }
    }
  });
});
