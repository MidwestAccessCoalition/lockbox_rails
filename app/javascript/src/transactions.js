const updateTotal = () => {
  let total = 0;
  computeMileage();
  const transactions = $("#lockbox_transactions input[name*='amount']:visible");
  const entries = transactions.map((i, t) => $(t).val());
  for (var i = 0; i < entries.length; i++) {
    const value = parseFloat(entries[i]);
    if (!isNaN(value)) {
      total += value;
    }
  }
  $('#total').text(`Total: \$${(Math.round(total * 100) / 100).toFixed(2)}`);
};

const computeMileage = () => {
  const distances = $("#lockbox_transactions input[name*='distance']:visible");
  distances.each((index, distance) => {
    const row = $(distance).parents('.row');
    const amount = $(row).find('.amount-field input');
    newAmount = $(distance).val() * 0.2;
    amount.val((Math.round(newAmount * 100) / 100).toFixed(2));
  });
};

const rowToGas = row => {
  const distance = $(row).find('.distance-field input');
  const amount = $(row).find('.amount-field input');
  $(row).addClass('mileage-row');
  $(row)
    .find('.amount-field label')
    .tooltip({ animation: false });
  distance.parent().show();
  distance.val(0);
  amount.val(0);
  amount.prop('readonly', true);
  distance.focus();
};

const rowFromGas = row => {
  const distance = $(row).find('.distance-field input');
  const amount = $(row).find('.amount-field input');
  $(row).removeClass('mileage-row');
  $(row)
    .find('.amount-field label')
    .tooltip('disable');
  distance.parent().hide();
  amount.prop('readonly', false);
  amount.focus();
  if (distance.val() != 0) {
    distance.val(0);
    amount.val(0);
  }
};

const gasSelectName = "gas_reimbursements"

const updateTransaction = select => {
  const row = $(select).parents('.row');
  if (select.value == gasSelectName) {
    rowToGas(row);
  } else {
    rowFromGas(row);
  }
};

const setupTotal = () => {
  let transactions = $('#lockbox_transactions');
  if (transactions === null) {
    return false;
  }
  transactions.on('keyup', updateTotal);
  transactions.on('change', updateTotal);
  transactions.on('paste', updateTotal);
  transactions.on('cocoon:after-remove', updateTotal);
  updateTotal();
};

const setupMileage = () => {
  let transactions = $('#lockbox_transactions');
  if (transactions === null) {
    return false;
  }
  transactions.on('change', 'select', event => updateTransaction(event.target));
};

document.addEventListener('turbolinks:load', () => {
  setupTotal();
  setupMileage();
  $('.amount-field label:visible').tooltip('dispose');
  $('.mileage-row .amount-field label:visible').tooltip({ animation: false });
});
