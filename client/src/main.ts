import { mount } from 'svelte';
import './assets/main.css';
import App from './App.svelte';

const target = document.getElementById('app');
if (!target) throw new Error('No app element found');

const app = mount(App, {
  target,
});

export default app;
