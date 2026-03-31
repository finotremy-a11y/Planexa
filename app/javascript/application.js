// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { initPWA } from "pwa/register"
import "controllers"
import "chartkick"
import "Chart.bundle"

initPWA()
