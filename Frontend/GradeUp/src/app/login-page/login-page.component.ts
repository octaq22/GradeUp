import { Component } from '@angular/core';

@Component({
  selector: 'app-login',
  standalone: true,
  templateUrl: './login-page.component.html',
  imports: [],
  styleUrl: './login-page.component.css'
})
export class LoginComponent {
  username: string = '';
  password: string = '';
  rememberMe: boolean = false;
  imagePath: string = "assets/images/logo.svg";

  onSubmit(): void {
    console.log('Form submitted');
    console.log('Username:', this.username);
    console.log('Password:', this.password);
    console.log('Remember Me:', this.rememberMe);

  }
}

export class LoginPageComponent {
}
