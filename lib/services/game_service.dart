import '../models/game_object.dart';
import '../models/player.dart';

class GameService {

  //이동
  void movePlayer({
    required Player player,
    required double dx,
    required double dy,
    required double worldWidth,
    required double worldHeight,
    required double playerSize,
  }) {
  player.x += dx;
  player.y += dy;

  if (player.x < 0) player.x = 0;
  if (player.y < 0) player.y = 0;

  if (player.x > worldWidth - playerSize) {
  player.x = worldWidth - playerSize;
  }

  if (player.y > worldHeight - playerSize) {
  player.y = worldHeight - playerSize;
  }
    // GameObject? findInteractableObject(
    //     Player player,
    //     List<GameObject> objects,
    // )
  }

    GameObject? findInteractableObject(
    Player player,
    List<GameObject> objects,
    ) {
    //interactableObject = null;

    for (final obj in objects) {
      final dx = (player.x - obj.x).abs();
      final dy = (player.y - obj.y).abs();

      if (dx < 50 && dy < 50) {
        return obj;
      }
    }
    return null;
  }
}
