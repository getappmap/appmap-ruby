const statusElement = document.querySelector('#appmap-record-status');
const recordButton = document.querySelector('#appmap-record');
let ellipsisTimeoutId = -1;

function makeRequest(method) {
  const req = new XMLHttpRequest();
  req.open(method, '/_appmap/record');
  req.send();
}

function startRecording() {
  const req = new XMLHttpRequest();
  req.open('POST', '/_appmap/record');
  req.send();
  displayRecording(true);
}

function stopRecording() {
  const req = new XMLHttpRequest();
  req.open('DELETE', '/_appmap/record');
  req.send();
  req.onload = () => {
    if (req.status === 200) {
      if ( req.response ) {
        saveScenario(JSON.parse(req.response));
      }
    }
  };
  displayRecording(false);
}

// POST the data to a new _blank window, so that AppLand
// can handle authentication and permissions through the browser.
function saveScenario(saveResponse) {
  const url = saveResponse.url;
  const data = saveResponse.data;

  const form = document.createElement("form");
  form.setAttribute("method", "post");
  form.setAttribute("action", url);
  form.setAttribute("target", "_blank");
  var input = document.createElement('input');
  input.type = 'hidden';
  input.name = 'data';
  input.value = JSON.stringify(data);
  form.appendChild(input);

  document.body.appendChild(form);
  form.submit();
  document.body.removeChild(form);
}

function animateEllipsis(isAnimating, numEllipsis) {
  if (!isAnimating) {
    if (ellipsisTimeoutId >= 0) {
      clearTimeout(ellipsisTimeoutId);
      ellipsisTimeoutId = -1;
    }
    return;
  }

  ellipsisTimeoutId = setTimeout(() => {
    let n = numEllipsis;
    if (!n || n > 3) {
      n = 0;
    }
    
    let text = statusElement.innerText.replace(/\./g, '');
    for (let i = 0; i < n; ++i) {
      text += '.';
    }

    statusElement.innerText = text;

    animateEllipsis(true, n + 1);
  }, 250);
}

function displayRecording(isRecording) {
  recordButton.checked = isRecording;
  statusElement.innerText = isRecording ? 'Recording' : 'Ready';
  animateEllipsis(isRecording);
}

recordButton.addEventListener('change', (e) => {
  e.target.checked ? startRecording() : stopRecording()
});

function onLoad() {
  const req = new XMLHttpRequest();
  req.open('GET', '/_appmap/record');
  req.send();
  req.onload = () => {
    if (req.status === 200) {
      const recordingState = JSON.parse(req.response);
      displayRecording(recordingState.enabled);
    }
  };
}

document.addEventListener('DOMContentLoaded', onLoad, false);


