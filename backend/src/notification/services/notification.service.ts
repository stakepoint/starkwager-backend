import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { CreateNotificationDto } from '../dtos/notification.dto';

@Injectable()
export class NotificationService {
  constructor(private readonly prisma: PrismaService) {}

  async createNotification(userId: string, data: CreateNotificationDto) {
    const { isRead, message, type } = data;
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        message,
        type,
        isRead,
      },
    });
    return { data: notification };
  }

  async getNotifications(
    userId: string,
    isRead?: boolean,
    page?: number,
    limit?: number,
  ): Promise<{ data: Notification[]; total: number }> {
    const skip = page && limit ? (page - 1) * limit : undefined;

    const query = {
      where: {
        userId,
        isRead,
      },
      skip,
      take: limit,
    };

    const total = await this.prisma.notification.count({
      where: query.where,
    });

    const notifications = await this.prisma.notification.findMany(query);

    return { data: notifications, total };
  }

  async markAsRead(id: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    const updated = await this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
    return { isRead: updated.isRead, message: 'marked' };
  }

  async deleteNotification(id: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id },
    });
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    await this.prisma.notification.delete({ where: { id } });
    return { data: true, message: 'Deleted' };
  }

  async getANotification(id: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    return { data: notification };
  }
}
