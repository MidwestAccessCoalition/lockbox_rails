const fadeAlert = () => {
  const alerts = Array.from(document.getElementsByClassName('fade'));
  alerts.forEach(alert => (alert.style.maxHeight = '0'));
};

const setupAlerts = () => {
  window.setTimeout(fadeAlert, 3000);
  document.addEventListener('ajax:success', response => {
    const data = response.detail[0];
    if (data.error) {
      console.log(data.error);
    }
  });
};

document.addEventListener('DOMContentLoaded', () => {
  setupAlerts();
});
