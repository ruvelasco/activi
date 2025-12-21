# Instrucciones para Activar el Panel Dinámico de Actividades

## ¿Qué cambia?

El panel actual (`ActivityCreatorPanel`) tiene las actividades **hardcodeadas**. El nuevo panel dinámico (`DynamicActivityCreatorPanel`) carga las actividades desde el **backend** y respeta:

- ✅ El orden configurado desde la interfaz de administración
- ✅ Solo muestra actividades habilitadas
- ✅ Muestra las badges "NUEVA" automáticamente
- ✅ Respeta los colores e iconos configurados

## Pasos para activar el panel dinámico

### 1. Agregar el import en main.dart

Busca la sección de imports en `lib/main.dart` y agrega:

```dart
import 'widgets/dynamic_activity_creator_panel.dart';
```

### 2. Crear el método de mapeo de actividades

Agrega este método en la clase `_MyHomePageState` (después de los métodos de generación de actividades):

```dart
void _handleActivitySelection(String activityName) {
  final activityMap = {
    'activity_pack': _generateActivityPack,
    'shadow_matching': _generateShadowMatchingActivity,
    'puzzle': _generatePuzzleActivity,
    'writing_practice': _generateWritingPracticeActivity,
    'counting_practice': _generateCountingActivity,
    'phonological_awareness': _generatePhonologicalAwarenessActivity,
    'phonological_board': _generatePhonologicalBoardActivity,
    'series': _generateSeriesActivity,
    'symmetry': _generateSymmetryActivity,
    'syllable_vocabulary': _generateSyllableVocabularyActivity,
    'semantic_field': _generateSemanticFieldActivity,
    'instructions': _generateInstructionsActivity,
    'phrases': _generatePhrasesActivity,
    'card': _generateCardActivity,
    'classification': _generateClassificationActivity,
    'phonological_squares': _generatePhonologicalSquaresActivity,
    'crossword': _generateCrosswordActivity,
    'word_search': _generateWordSearchActivity,
    'sentence_completion': _generateSentenceCompletionActivity,
  };

  final handler = activityMap[activityName];
  if (handler != null) {
    handler();
  } else {
    print('Actividad no encontrada: $activityName');
  }
}
```

### 3. Reemplazar el panel en el switch

En el método `_buildSidebarContent()`, busca el caso `SidebarMode.creador` (alrededor de la línea 5100) y reemplaza:

**ANTES:**
```dart
case SidebarMode.creador:
  return ActivityCreatorPanel(
    onActivityPack: _generateActivityPack,
    onShadowMatching: _generateShadowMatchingActivity,
    // ... muchas más líneas
  );
```

**DESPUÉS:**
```dart
case SidebarMode.creador:
  return DynamicActivityCreatorPanel(
    onActivitySelected: _handleActivitySelection,
  );
```

## Beneficios

1. **Gestión centralizada**: Ahora puedes gestionar las actividades desde la interfaz de administración sin tocar código
2. **Orden personalizable**: El orden se controla desde el backend
3. **Habilitar/deshabilitar fácilmente**: Sin recompilar la app
4. **Actualizaciones en tiempo real**: Al recargar, verás los cambios del backend
5. **Fallback automático**: Si el backend falla, usa actividades por defecto

## Probarlo

1. Ejecuta `flutter run`
2. Abre el panel de creador de actividades
3. Verás un botón de recarga arriba
4. Las actividades se cargan desde el backend
5. Ve a "Administrar tipos de actividad" para cambiar el orden o habilitar/deshabilitar
6. Recarga el panel de creador para ver los cambios

## Rollback (volver al panel anterior)

Si quieres volver al panel hardcodeado, simplemente deshaz el cambio en el paso 3.
