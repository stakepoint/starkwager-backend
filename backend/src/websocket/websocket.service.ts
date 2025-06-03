import { Injectable, Logger } from '@nestjs/common';
import { Socket } from 'socket.io';

@Injectable()
export class WebsocketService {
  private readonly logger = new Logger(WebsocketService.name);
  private readonly connectedClients = new Map<string, Socket>();

  handleConnection(client: Socket) {
    this.connectedClients.set(client.id, client);
    this.logger.log(`Client ${client.id} added to connected clients`);
  }

  handleDisconnect(client: Socket) {
    this.connectedClients.delete(client.id);
    this.logger.log(`Client ${client.id} removed from connected clients`);
  }

  getConnectedClients(): Map<string, Socket> {
    return this.connectedClients;
  }

  broadcastToAll(event: string, payload: any) {
    this.connectedClients.forEach((client) => {
      client.emit(event, payload);
    });
  }

  broadcastToRoom(room: string, event: string, payload: any) {
    this.connectedClients.forEach((client) => {
      if (client.rooms.has(room)) {
        client.emit(event, payload);
      }
    });
  }
}
