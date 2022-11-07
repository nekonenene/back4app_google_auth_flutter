# back4app_google_auth_flutter


## Setup

### 1. Clone this repository

### 2. Set environment variables

```sh
cp .env.default .env
```

Set `BACK4APP_APPLICATION_ID` and `BACK4APP_CLIENT_KEY` in `.env`.  
(Ref: https://www.back4app.com/docs/react/quickstart )


### 3. Download google-services.json

Download `google-services.json` from Firebase and put it into `android/app` directory.  
(Ref: https://firebase.google.com/docs/android/setup)


### 4. Install dependencies

```sh
flutter pub get
```


## Run

```sh
flutter run
```
