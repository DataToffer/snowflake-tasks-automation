# 📦 Guía: Subir Repositorio a GitHub

## Paso 1: Crear Repositorio en GitHub

1. Ve a https://github.com/new
2. Configura:
   - **Repository name:** `snowflake-tasks-automation`
   - **Description:** `Automatización de métricas con Snowflake Tasks - Caso Smart Desk (UCM Master Data Science)`
   - **Visibility:** Public
   - **NO** inicialices con README (ya lo tienes)
3. Click "Create repository"

---

## Paso 2: Configurar Git Localmente

Desde tu terminal, en la carpeta del proyecto:

```bash
# Navegar a la carpeta del repositorio
cd /ruta/a/snowflake-tasks-automation

# Inicializar Git (si no lo has hecho)
git init

# Configurar tu información (si es primera vez)
git config --global user.name "Tu Nombre"
git config --global user.email "tu-email@example.com"
```

---

## Paso 3: Preparar el Commit Inicial

```bash
# Verificar archivos a incluir
git status

# Agregar todos los archivos
git add .

# Verificar que todo está staged
git status

# Crear commit inicial
git commit -m "Initial commit: Snowflake Tasks automation project"
```

---

## Paso 4: Conectar con GitHub

Reemplaza `[tu-usuario]` con tu usuario real de GitHub:

```bash
# Agregar remote
git remote add origin https://github.com/[tu-usuario]/snowflake-tasks-automation.git

# Verificar remote
git remote -v

# Push al repositorio
git branch -M main
git push -u origin main
```

---

## Paso 5: Verificar en GitHub

1. Ve a https://github.com/[tu-usuario]/snowflake-tasks-automation
2. Verifica que todos los archivos se subieron correctamente
3. Verifica que el README.md se muestra correctamente

---

## Paso 6: Configurar Badges (Opcional pero Recomendado)

Edita el README.md y asegúrate que los badges funcionen:

```markdown
[![Snowflake](https://img.shields.io/badge/Snowflake-Tasks-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![SQL](https://img.shields.io/badge/SQL-Advanced-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)](https://www.snowflake.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
```

---

## Paso 7: Crear Topics (GitHub Tags)

En GitHub, ve a Settings > General > Topics y agrega:

- `snowflake`
- `sql`
- `data-engineering`
- `automation`
- `tasks`
- `etl`
- `data-science`
- `university`
- `ucm`

Esto ayuda a que la gente encuentre tu repositorio.

---

## Paso 8: Habilitar GitHub Pages (Opcional)

Si quieres que la documentación sea accesible vía web:

1. Settings > Pages
2. Source: Deploy from a branch
3. Branch: main / (root)
4. Save

Tu docs estará disponible en: `https://[tu-usuario].github.io/snowflake-tasks-automation/`

---

## Comandos Git Útiles para el Futuro

### Actualizar el repositorio después de cambios

```bash
# Ver cambios
git status

# Agregar cambios específicos
git add archivo.sql
git add docs/nuevo_tutorial.md

# O agregar todos los cambios
git add .

# Commit con mensaje descriptivo
git commit -m "Add: Nueva sección de troubleshooting en FAQ"

# Push a GitHub
git push origin main
```

### Crear una nueva rama para features

```bash
# Crear y cambiar a nueva rama
git checkout -b feature/streams-integration

# Hacer cambios...
git add .
git commit -m "Add: Ejemplo de Tasks con Streams"

# Push de la rama
git push origin feature/streams-integration

# En GitHub: Crear Pull Request de esta rama a main
```

### Ver historial

```bash
# Ver commits
git log --oneline

# Ver diferencias
git diff
```

---

## Estructura de Mensajes de Commit (Convención)

Usa prefijos claros:

```bash
# Nuevas features
git commit -m "Add: Tutorial de Tasks con dependencias"

# Correcciones
git commit -m "Fix: Corregir typo en script SQL"

# Documentación
git commit -m "Docs: Actualizar FAQ con nuevas preguntas"

# Mejoras de código
git commit -m "Refactor: Optimizar query de agregación"

# Cambios menores
git commit -m "Chore: Actualizar .gitignore"
```

---

## Troubleshooting Común

### Error: "remote origin already exists"

```bash
# Ver remotes actuales
git remote -v

# Eliminar remote existente
git remote remove origin

# Agregar nuevamente
git remote add origin https://github.com/[tu-usuario]/snowflake-tasks-automation.git
```

### Error: "failed to push some refs"

```bash
# Pull primero (si alguien más hizo cambios)
git pull origin main --rebase

# Luego push
git push origin main
```

### Error: "Authentication failed"

Necesitas un Personal Access Token (PAT):

1. GitHub > Settings > Developer Settings > Personal Access Tokens
2. Generate new token (classic)
3. Scopes: `repo` (full control)
4. Copiar el token
5. Usarlo como password al hacer push

O mejor, configura SSH:

```bash
# Generar SSH key
ssh-keygen -t ed25519 -C "tu-email@example.com"

# Copiar la clave pública
cat ~/.ssh/id_ed25519.pub

# Agregar en GitHub: Settings > SSH and GPG keys > New SSH key

# Cambiar remote a SSH
git remote set-url origin git@github.com:[tu-usuario]/snowflake-tasks-automation.git
```

---

## Checklist Final Antes de Hacer Público

- [ ] README.md completo y sin placeholder [tu-usuario]
- [ ] LICENSE file presente
- [ ] .gitignore configurado (sin credenciales)
- [ ] Scripts SQL testeados y funcionando
- [ ] Documentación clara y sin errores
- [ ] Links internos funcionando
- [ ] Contact info actualizado
- [ ] Badges funcionando
- [ ] Topics configurados en GitHub
- [ ] Repository description clara

---

## Siguiente Paso: LinkedIn Post

Una vez el repositorio esté público y verificado:

1. ✅ Copia el URL real del repo
2. ✅ Reemplaza `[tu-usuario]` en LINKEDIN_POST.txt
3. ✅ Publica en LinkedIn (martes/miércoles 8-10 AM)
4. ✅ Pin el primer comentario con links directos
5. ✅ Responde todos los comentarios en las primeras 2 horas

---

## Recursos Adicionales

- [GitHub Docs: Creating a repo](https://docs.github.com/en/get-started/quickstart/create-a-repo)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Writing Good Commit Messages](https://chris.beams.io/posts/git-commit/)

---

**¿Necesitas ayuda?**

- 📧 GitHub Support: https://support.github.com/
- 💬 Git Community: https://git-scm.com/community
- 📖 Pro Git Book (gratis): https://git-scm.com/book/en/v2

---

¡Éxito con tu repositorio! 🚀
