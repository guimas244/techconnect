# Configuração do Google Sign-In para o projeto

## Informações do Projeto

- **Package Name:** `com.example.techconnect`
- **SHA-1 PC ANTIGO:** `EE:9D:36:26:2A:AE:45:A8:00:71:22:39:A0:E1:C5:6D:39:1F:3F:1F`
- **SHA-1 PC NOVO:** `88:36:4B:F1:C8:D9:75:2E:C2:B5:4B:98:51:5F:BC:E0:7F:DC:DD:25`

## Passo a Passo para Configurar no Firebase Console

### IMPORTANTE: Você precisa adicionar AMBOS os SHA-1 no Firebase!

Isso permite que o app funcione tanto no PC antigo quanto no novo.

### 1. Acessar o Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Faça login com sua conta Google
3. Selecione o projeto do TechConnect

### 2. Adicionar AMBOS os SHA-1 ao App Android

1. No menu lateral esquerdo, clique no ícone de **engrenagem ⚙️**
2. Clique em **Configurações do projeto**
3. Role até a seção **"Seus aplicativos"**
4. Encontre o app Android com package `com.example.techconnect`
5. Role até **"Impressões digitais de certificado SHA"**
6. **ADICIONE o SHA-1 do PC NOVO** (se ainda não estiver):
   - Clique em **"Adicionar impressão digital"**
   - Cole: `88:36:4B:F1:C8:D9:75:2E:C2:B5:4B:98:51:5F:BC:E0:7F:DC:DD:25`
   - Clique em **Salvar**
7. **Verifique se o SHA-1 do PC ANTIGO ainda está lá**:
   - Deve aparecer: `EE:9D:36:26:2A:AE:45:A8:00:71:22:39:A0:E1:C5:6D:39:1F:3F:1F`
   - Se não estiver, adicione também!
8. No final, você deve ter **2 SHA-1** cadastrados

### 3. Configurar OAuth no Google Cloud Console

1. Acesse: https://console.cloud.google.com/
2. Selecione o mesmo projeto do Firebase
3. No menu lateral, vá em **APIs e serviços → Credenciais**
4. Procure por **"ID do cliente OAuth 2.0 para Android"**
5. Você deve ter **2 credenciais OAuth** (uma para cada SHA-1):

#### Credencial 1 - PC Antigo:
   - **Nome do pacote:** `com.example.techconnect`
   - **SHA-1:** `EE:9D:36:26:2A:AE:45:A8:00:71:22:39:A0:E1:C5:6D:39:1F:3F:1F`

#### Credencial 2 - PC Novo (criar se não existir):
   - Clique em **"Criar credenciais" → "ID do cliente OAuth"**
   - Selecione **Android**
   - Nome: "TechConnect Android (PC Novo)"
   - Nome do pacote: `com.example.techconnect`
   - Impressão digital SHA-1: `88:36:4B:F1:C8:D9:75:2E:C2:B5:4B:98:51:5F:BC:E0:7F:DC:DD:25`
   - Clique em **Criar**

### 4. Verificar google-services.json

1. Volte ao Firebase Console
2. Vá em **Configurações do projeto**
3. Na seção do app Android (`com.example.techconnect`)
4. Clique em **google-services.json** para baixar
5. Verifique se o arquivo local está atualizado: `android/app/google-services.json`
6. Se baixou um novo, substitua o arquivo antigo

### 5. Testar

Após fazer as configurações acima:

1. Aguarde 5-10 minutos para as mudanças propagarem
2. Execute: `flutter clean`
3. Reinicie o app no emulador
4. Tente conectar ao Google Drive
5. Deve funcionar sem erros!

## Resumo Visual

```
Firebase Console:
├─ App: com.example.techconnect
   ├─ SHA-1 #1: EE:9D:36:... (PC Antigo) ✅
   └─ SHA-1 #2: 88:36:4B:... (PC Novo) ✅

Google Cloud Console:
├─ OAuth Client #1: com.example.techconnect + EE:9D:36:... ✅
└─ OAuth Client #2: com.example.techconnect + 88:36:4B:... ✅
```

## Comandos Úteis

### Gerar SHA-1 novamente (se necessário):

#### No Windows:

```powershell
& 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### No Linux/Mac:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Solução de Problemas

Se ainda der erro após configurar:

1. Verifique se AMBOS os SHA-1 estão no Firebase
2. Verifique se tem 2 credenciais OAuth no Google Cloud Console
3. Limpe o cache: `flutter clean && flutter pub get`
4. Desinstale e reinstale o app no emulador
5. Aguarde 10-15 minutos (propagação pode demorar)
6. Reinicie o emulador Android

## Por que preciso de 2 SHA-1?

Cada computador gera um keystore de debug diferente quando você instala o Android SDK. O SHA-1 é gerado a partir desse keystore. Por isso:

- **PC Antigo:** SHA-1 `EE:9D:36:...`
- **PC Novo:** SHA-1 `88:36:4B:...`

Adicionando ambos no Firebase, o Google Sign-In funciona nos 2 computadores! 🎉
