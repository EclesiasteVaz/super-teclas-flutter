# Contribuindo com o Super Teclas 🚀

Obrigado pelo interesse em contribuir com o **Super Teclas**! Este é um projeto de código aberto focado em alta performance, arquitetura limpa e digitação rápida contra o tempo em Flutter.

Toda contribuição — seja reportando um bug, sugerindo novas palavras, melhorando o design ou otimizando código — é muito bem-vinda.

---

## 📋 Regras de Ouro do Projeto

Para mantermos a consistência e a excelência técnica da base de código, todas as contribuições devem seguir rigorosamente as convenções abaixo (também descritas em detalhes no [`AGENTS.md`](AGENTS.md)):

1. **Sem Comentários no Código Dart:** O código deve ser autoexplicativo através de nomes claros para classes, métodos e variáveis.
2. **Imports Absolutos:** Sempre use imports com o prefixo `package:super_teclas/...`. Nunca utilize imports relativos (`../`).
3. **Sem Gerenciadores de Estado Externos:** O projeto utiliza nativamente `ChangeNotifier` + `ListenableBuilder` + `setState`. Não adicione Provider, Riverpod, Bloc, GetX ou MobX.
4. **Novas Dependências:** Não adicione novos pacotes ao `pubspec.yaml` sem antes abrir uma issue para discutir a real necessidade com a comunidade.
5. **Zero Segredos:** Nunca comite arquivos `.env`, chaves de API ou credenciais de serviços no repositório.

---

## 🛠️ Como Contribuir

### 1. Preparando o Ambiente

1. Faça um Fork do repositório no GitHub.
2. Clone o seu fork localmente:
   ```bash
   git clone https://github.com/SEU-USUARIO/super-teclas-flutter.git
   cd super-teclas-flutter
   ```
3. Instale as dependências:
   ```bash
   flutter pub get
   ```

### 2. Criando uma Branch

Crie uma branch descritiva a partir da branch ativa de desenvolvimento (`develop` ou `master`):
```bash
git checkout -b feature/minha-melhoria
# ou
git checkout -b fix/correcao-bug
```

### 3. Rodando os Testes e Linter

Antes de submeter o seu Pull Request, certifique-se de que o linter e todos os testes automatizados passem com sucesso:

```bash
# Verificar boas práticas e lints
flutter analyze

# Rodar todos os testes automatizados
flutter test
```

### 4. Commits

Escreva mensagens de commit curtas, claras e no modo imperativo em português (ou inglês):
- ✅ `Corrige calculo de precisao na tela final`
- ✅ `Adiciona suporte a novo atalho de teclado`
- ❌ `arrumei um bug`

### 5. Abrindo o Pull Request

1. Faça o push para o seu fork:
   ```bash
   git push origin feature/minha-melhoria
   ```
2. Abra um Pull Request no repositório principal descrevendo claramente:
   - Qual problema o PR resolve.
   - O que foi alterado.
   - Confirmação de que `flutter analyze` e `flutter test` passaram sem erros.

---

## 💬 Dúvidas ou Sugestões?

Abra uma [Issue no GitHub](https://github.com/eclesiastes-vaz/super-teclas-flutter/issues) para compartilhar ideias ou tirar dúvidas sobre a arquitetura.
