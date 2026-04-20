<template>
  <main
    style="
      font-family: Inter, system-ui, sans-serif;
      margin: 2rem;
      max-width: 760px;
    "
  >
    <h1>AttendEase Admin</h1>
    <p>Architecture scaffold is ready with Firebase backend functions.</p>

    <h2>Included flows</h2>
    <ul>
      <li>QR token generation + validation</li>
      <li>GPS proximity enforcement (Haversine)</li>
      <li>Check-in / check-out callable APIs</li>
      <li>Auto-close missed check-outs</li>
      <li>Notification dispatcher (idempotent)</li>
      <li>Attendance audit logging</li>
      <li>Leave overlap reconciliation</li>
    </ul>
  </main>
</template>
