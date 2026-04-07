import './input.css'
import { Elm } from './Main.elm'

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: JSON.parse(localStorage.getItem('session'))
})

app.ports.saveSession.subscribe(data => {
  localStorage.setItem('session', JSON.stringify(data))
})

app.ports.clearSession.subscribe(() => {
  localStorage.removeItem('session')
})
